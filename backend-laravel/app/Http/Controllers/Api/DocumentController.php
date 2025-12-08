<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreDocumentRequest;
use App\Http\Requests\UpdateDocumentRequest;
use App\Http\Requests\UpdateDocumentStatusRequest;
use App\Models\Document;
use App\Models\ActivityHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DocumentController extends Controller
{
    /**
     * Get paginated list of documents with role-based filtering.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $perPage = min($request->input('per_page', 15), 100);
        
        // Base query
        $query = Document::with('user:id_user,username,nama_lengkap');
        
        // Role-based filtering
        if ($user->isAdmin()) {
            // Admin: Access all documents within their institution
            $query->forInstitution($user->instansi);
        } elseif ($user->isPimpinan()) {
            // Pimpinan: Access all documents in institution
            $query->forInstitution($user->instansi);
        } else {
            // User: Only documents they created or assigned to them
            $query->where(function ($q) use ($user) {
                $q->where('id_user', $user->id_user)
                  ->orWhere('kode_user', $user->kode_user);
            });
        }
        
        // Apply filters
        if ($request->filled('status')) {
            $query->status($request->status);
        }
        
        if ($request->filled('sifat')) {
            $query->where('sifat', $request->sifat);
        }
        
        if ($request->filled('search')) {
            $query->search($request->search);
        }
        
        if ($request->filled('date_from')) {
            $query->where('tgl_surat', '>=', $request->date_from);
        }
        
        if ($request->filled('date_to')) {
            $query->where('tgl_surat', '<=', $request->date_to);
        }
        
        if ($request->filled('kategori_surat')) {
            $query->where('kategori_surat', $request->kategori_surat);
        }
        
        // Order by date descending
        $query->orderBy('tgl_surat', 'desc');
        
        $documents = $query->paginate($perPage);
        
        return response()->json([
            'status' => 200,
            'data' => $documents->items(),
            'meta' => [
                'current_page' => $documents->currentPage(),
                'per_page' => $documents->perPage(),
                'total' => $documents->total(),
                'last_page' => $documents->lastPage(),
            ],
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Get single document detail.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        
        $document = Document::with('user:id_user,username,nama_lengkap')->find($id);
        
        if (!$document) {
            return response()->json([
                'status' => 404,
                'message' => 'Document not found',
                'timestamp' => now()->toIso8601String(),
            ], 404);
        }
        
        // Check authorization
        $canAccess = false;
        if ($user->isAdmin() && $document->id_instansi === $user->instansi) {
            $canAccess = true;
        } elseif ($user->isPimpinan() && $document->id_instansi === $user->instansi) {
            $canAccess = true;
        } elseif ($document->id_user === $user->id_user) {
            $canAccess = true;
        }
        
        if (!$canAccess) {
            return response()->json([
                'status' => 403,
                'message' => 'Unauthorized to access this document',
                'timestamp' => now()->toIso8601String(),
            ], 403);
        }
        
        // Mark as read
        $document->markAsRead($user->isPimpinan());
        
        // Log activity
        ActivityHistory::log(
            userId: $user->id_user,
            action: 'view_document',
            documentId: $document->id_sm,
            description: "Viewed document: {$document->no_surat}"
        );
        
        return response()->json([
            'status' => 200,
            'data' => $document,
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Create new document.
     */
    public function store(StoreDocumentRequest $request): JsonResponse
    {
        $user = $request->user();
        
        // Generate document number (simplified - you may want a more complex logic)
        $lastDoc = Document::whereYear('created_at', now()->year)->max('id_sm');
        $nextNumber = str_pad(($lastDoc + 1) ?: 1, 5, '0', STR_PAD_LEFT);
        
        $document = Document::create([
            'no_surat' => $nextNumber,
            'tgl_ns' => now()->toDateString(),
            'no_asal' => $request->no_asal,
            'tgl_surat' => $request->tgl_surat,
            'pengirim' => $request->pengirim,
            'penerima' => $request->penerima,
            'perihal' => $request->perihal,
            'sifat' => $request->sifat,
            'kategori_surat' => $request->kategori_surat,
            'klasifikasi_surat' => $request->klasifikasi_surat,
            'lampiran' => $request->lampiran,
            'token_lampiran' => $request->token_lampiran,
            'id_user' => $user->id_user,
            'kode_user' => $user->kode_user,
            'id_instansi' => $user->instansi,
            'tgl_sm' => now()->toDateString(),
            'status' => 'Dokumen',
        ]);
        
        // Log activity
        ActivityHistory::log(
            userId: $user->id_user,
            action: 'create_document',
            documentId: $document->id_sm,
            description: "Created document: {$document->no_surat}"
        );
        
        return response()->json([
            'status' => 201,
            'message' => 'Document created successfully',
            'data' => $document,
            'timestamp' => now()->toIso8601String(),
        ], 201);
    }

    /**
     * Update existing document.
     */
    public function update(UpdateDocumentRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        
        $document = Document::find($id);
        
        if (!$document) {
            return response()->json([
                'status' => 404,
                'message' => 'Document not found',
                'timestamp' => now()->toIso8601String(),
            ], 404);
        }
        
        // Check authorization
        $canUpdate = false;
        if ($user->isAdmin() && $document->id_instansi === $user->instansi) {
            $canUpdate = true;
        } elseif ($document->id_user === $user->id_user && $document->canBeEdited()) {
            $canUpdate = true;
        }
        
        if (!$canUpdate) {
            return response()->json([
                'status' => 403,
                'message' => 'Unauthorized to update this document or document cannot be edited',
                'timestamp' => now()->toIso8601String(),
            ], 403);
        }
        
        $document->update($request->validated());
        
        // Log activity
        ActivityHistory::log(
            userId: $user->id_user,
            action: 'update_document',
            documentId: $document->id_sm,
            description: "Updated document: {$document->no_surat}"
        );
        
        return response()->json([
            'status' => 200,
            'message' => 'Document updated successfully',
            'data' => $document->fresh(),
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Soft delete document.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        
        if (!$user->isAdmin()) {
            return response()->json([
                'status' => 403,
                'message' => 'Only administrators can delete documents',
                'timestamp' => now()->toIso8601String(),
            ], 403);
        }
        
        $document = Document::find($id);
        
        if (!$document) {
            return response()->json([
                'status' => 404,
                'message' => 'Document not found',
                'timestamp' => now()->toIso8601String(),
            ], 404);
        }
        
        if (!$document->canBeDeleted()) {
            return response()->json([
                'status' => 403,
                'message' => 'Document cannot be deleted as it has dispositions',
                'timestamp' => now()->toIso8601String(),
            ], 403);
        }
        
        $document->delete();
        
        // Log activity
        ActivityHistory::log(
            userId: $user->id_user,
            action: 'delete_document',
            documentId: $document->id_sm,
            description: "Deleted document: {$document->no_surat}"
        );
        
        return response()->json([
            'status' => 200,
            'message' => 'Document deleted successfully',
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Update document status.
     */
    public function updateStatus(UpdateDocumentStatusRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        
        if (!$user->isPimpinan() && !$user->isAdmin()) {
            return response()->json([
                'status' => 403,
                'message' => 'Only administrators or leadership can update document status',
                'timestamp' => now()->toIso8601String(),
            ], 403);
        }
        
        $document = Document::find($id);
        
        if (!$document) {
            return response()->json([
                'status' => 404,
                'message' => 'Document not found',
                'timestamp' => now()->toIso8601String(),
            ], 404);
        }
        
        // Check institution access for admin
        if ($user->isAdmin() && $document->id_instansi !== $user->instansi) {
            return response()->json([
                'status' => 403,
                'message' => 'Unauthorized to update this document',
                'timestamp' => now()->toIso8601String(),
            ], 403);
        }
        
        $oldStatus = $document->status;
        
        $document->update([
            'status' => $request->status,
            'disposisi' => $request->disposisi,
            'catatan' => $request->catatan,
            'tgl_disposisi' => now(),
        ]);
        
        // Log activity
        ActivityHistory::log(
            userId: $user->id_user,
            action: 'status_change',
            documentId: $document->id_sm,
            description: "Changed status from {$oldStatus} to {$request->status}",
            metadata: ['old_status' => $oldStatus, 'new_status' => $request->status]
        );
        
        return response()->json([
            'status' => 200,
            'message' => 'Document status updated successfully',
            'data' => $document->fresh(),
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
