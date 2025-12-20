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
use Illuminate\Support\Str;


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
        $query = Document::with(['user:id_user,username,nama_lengkap', 'lampirans']);

        // Role-based filtering
        // if ($user->isAdmin()) {
        //     // Admin: Access all documents within their institution
        //     $query->forInstitution($user->instansi);
        // } elseif ($user->isPimpinan()) {
        //     // Pimpinan: Access all documents in institution
        //     $query->forInstitution($user->instansi);
        // } else {
        //     // User: Only documents they created or assigned to them
        //     $query->where(function ($q) use ($user) {
        //         $q->where('id_user', $user->id_user)
        //             ->orWhere('kode_user', $user->kode_user);
        //     });
        // }

        // Apply filters
        // if ($request->filled('status')) {
        //     $query->status($request->status);
        // }

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

        if ($request->filled('dibaca')) {
            $dibaca = $request->dibaca;
            $query->where(function ($q) use ($dibaca, $user) {
                switch ($dibaca) {
                    case '1':
                        $q->where('dibaca', '1')
                            ->where('id_instansi', $user->instansi);
                        break;
                    case '2':
                        $q->where('dibaca', '1')
                            ->where('kode_user', $user->kode_user);
                        break;
                    case '3':
                        $q->where('dibaca', '3')
                            ->orWhere('id_status_rapat', '4');
                        break;
                    case '4':
                        $q->where('dibaca', '1')
                            ->orWhere('dibaca', '8');
                        break;
                    case '5':
                        $q->where('dibaca', '2');
                        break;
                    case '6':
                        $q->where('id_status_rapat', '2');
                        break;
                    case '7':
                        $q->where('dibaca', '2')
                            ->where(function ($subQ) use ($user) {
                                $subQ->where('kode_user_pimpinan', $user->kode_user)
                                    ->orWhere('dibaca_pimpinan', '1');
                            });
                        break;
                    case '8':
                        $q->where('dibaca', '8')
                            ->where('kode_user_pimpinan', $user->kode_user);
                        break;
                    case '9':
                        $q->where(function ($subQ) {
                            $subQ->where('id_status_rapat', '2')
                                ->where('dibaca', '7');
                        })
                            ->orWhere('kode_user_pimpinan', $user->kode_user);
                        break;
                    case '10':
                        $q->where(function ($subQ) {
                            $subQ->where('dibaca', '1')
                                ->orWhere('dibaca', '2');
                        })
                            ->where('id_instansi', $user->instansi);
                        break;
                    case '11':
                        $q->where(function ($subQ) {
                            $subQ->where('dibaca', '1')
                                ->orWhere('dibaca', '2');
                        })
                            ->where('kode_user', $user->kode_user);
                        break;
                    case '12':
                        $q->where(function ($subQ) {
                            $subQ->where('dibaca', '7')
                                ->orWhere('dibaca', '8');
                        })
                            ->where('id_instansi', $user->instansi);
                        break;
                    case '13':
                        $q->where(function ($subQ) {
                            $subQ->where('dibaca', '7')
                                ->orWhere('dibaca', '8');
                        })
                            ->where('kode_user', $user->kode_user);
                        break;
                    case '14':
                        $q->where('dibaca', '3')
                            ->where('id_instansi', $user->instansi);
                        break;
                    case '15':
                        $q->where('dibaca', '3')
                            ->where(function ($subQ) use ($user) {
                                $subQ->where('id_user', $user->id_user)
                                    ->orWhere('kode_user', $user->kode_user);
                            });
                        break;
                    case '16':
                        $q->where('dibaca', '0')
                            ->where('id_instansi', $user->instansi);
                        break;
                    case '17':
                        $q->where('dibaca', '0')
                            ->where(function ($subQ) use ($user) {
                                $subQ->where('id_user', $user->id_user)
                                    ->orWhere('kode_user', $user->kode_user);
                            });
                        break;
                    case '18':
                        $q->where('dibaca', '20')
                            ->where('id_instansi', $user->instansi);
                        break;
                    case '19':
                        $q->where('dibaca', '20')
                            ->where(function ($subQ) use ($user) {
                                $subQ->where('id_user', $user->id_user)
                                    ->orWhere('kode_user', $user->kode_user);
                            });
                        break;
                    case '20':
                        $q->where(function ($subQ) use ($user) {
                            $subQ->where(function ($deepQ) use ($user) {
                                $deepQ->where('dibaca', '3')
                                    ->where('status_instansi', '2')
                                    ->where('id_user_disposisi_leader', 'LIKE', '%:::' . $user->id_user . ':::%');
                            })->orWhere(function ($deepQ) use ($user) {
                                $deepQ->where('dibaca', '3')
                                    ->where('disposisi_ktu_leader', 'LIKE', '%:::' . $user->id_user . ':::%');
                            });
                        });
                        break;
                    default:
                        // Default behavior if dibaca is not in 1-20 or not handled
                        $q->where('dibaca', $dibaca);
                        break;
                }
            });
        }

        // Order by date descending
        $query->orderBy('tgl_surat', 'desc');
        $query->orderBy('id_sm', 'asc');
        $sql = $query->toSql();
        $rawSql = Str::replaceArray('?', $query->getBindings(), $sql);


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
            'debug_sql' => $rawSql,
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
            'kategori_kode' => $request->kategori_kode,
            'kategori_berkas' => $request->kategori_berkas,
            'kode_berkas' => $request->kode_berkas,
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
        $canUpdate = true;
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

        // $document->update($request->validated());
        $document->update($request->only($document->getFillable()));


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

        //Semua bisa menghapus sesuai kepemilikan berkas nya
        // if (!$user->isAdmin()) {
        //     return response()->json([
        //         'status' => 403,
        //         'message' => 'Only administrators can delete documents',
        //         'timestamp' => now()->toIso8601String(),
        //     ], 403);
        // }

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

    public function getLastNoSurat(Request $request): JsonResponse
    {
        $lastNoSurat = Document::query()
            ->select('no_surat')
            ->orderByRaw("CAST(TRIM(LEADING '0' FROM no_surat) AS UNSIGNED) DESC")
            ->limit(1)
            ->value('no_surat');
        $numeric = $lastNoSurat ? (int) ltrim($lastNoSurat, '0') : 0;
        $nextNumeric = $numeric + 1;
        $padLength = $lastNoSurat ? strlen($lastNoSurat) : 6;
        $nextNoSurat = str_pad((string) $nextNumeric, $padLength, '0', STR_PAD_LEFT);

        return response()->json([
            'status' => 200,
            'data' => [
                'last_no_surat' => $lastNoSurat,
                'next_no_surat' => $nextNoSurat,
            ],
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
