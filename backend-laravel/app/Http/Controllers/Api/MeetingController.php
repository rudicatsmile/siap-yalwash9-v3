<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\MeetingDecisionRequest;
use App\Models\Document;
use App\Models\ActivityHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MeetingController extends Controller
{
    /**
     * Get paginated list of meeting documents.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $perPage = min($request->input('per_page', 15), 100);
        
        // Base query for meetings
        $query = Document::with('user:id_user,username,nama_lengkap')
                         ->meetings();
        
        // Role-based filtering
        if ($user->isAdmin()) {
            $query->forInstitution($user->instansi);
        } elseif ($user->isPimpinan()) {
            $query->forInstitution($user->instansi);
        } else {
            $query->where(function ($q) use ($user) {
                $q->where('id_user', $user->id_user)
                  ->orWhere('kode_user', $user->kode_user);
            });
        }
        
        // Apply additional filters
        if ($request->filled('search')) {
            $query->search($request->search);
        }
        
        if ($request->filled('date_from')) {
            $query->where('tgl_agenda_rapat', '>=', $request->date_from);
        }
        
        if ($request->filled('date_to')) {
            $query->where('tgl_agenda_rapat', '<=', $request->date_to);
        }
        
        // Order by meeting date
        $query->orderBy('tgl_agenda_rapat', 'desc');
        
        $meetings = $query->paginate($perPage);
        
        return response()->json([
            'status' => 200,
            'data' => $meetings->items(),
            'meta' => [
                'current_page' => $meetings->currentPage(),
                'per_page' => $meetings->perPage(),
                'total' => $meetings->total(),
                'last_page' => $meetings->lastPage(),
            ],
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Record meeting decision.
     */
    public function decision(MeetingDecisionRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        
        // Only pimpinan can record meeting decisions
        if (!$user->isPimpinan()) {
            return response()->json([
                'status' => 403,
                'message' => 'Only leadership can record meeting decisions',
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
        
        // Verify document is a meeting
        if ($document->status !== 'Rapat') {
            return response()->json([
                'status' => 422,
                'message' => 'Document is not a meeting',
                'timestamp' => now()->toIso8601String(),
            ], 422);
        }
        
        // Check institution access
        if ($document->id_instansi !== $user->instansi) {
            return response()->json([
                'status' => 403,
                'message' => 'Unauthorized to access this meeting',
                'timestamp' => now()->toIso8601String(),
            ], 403);
        }
        
        // Update meeting decision
        $document->update([
            'disposisi_rapat' => $request->disposisi_rapat,
            'tgl_hasil_rapat' => $request->tgl_hasil_rapat ?? now(),
            'status' => $request->status ?? $document->status,
            'catatan' => $request->catatan,
        ]);
        
        // Log activity
        ActivityHistory::log(
            userId: $user->id_user,
            action: 'meeting_decision',
            documentId: $document->id_sm,
            description: "Recorded meeting decision for: {$document->no_surat}",
            metadata: ['decision' => $request->disposisi_rapat]
        );
        
        return response()->json([
            'status' => 200,
            'message' => 'Meeting decision recorded successfully',
            'data' => $document->fresh(),
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
