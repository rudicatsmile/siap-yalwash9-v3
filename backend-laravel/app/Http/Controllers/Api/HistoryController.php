<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HistoryController extends Controller
{
    /**
     * Get paginated user activity history.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $perPage = min($request->input('per_page', 20), 100);
        
        // Base query
        $query = ActivityHistory::with(['user:id_user,username,nama_lengkap', 'document:id_sm,no_surat,perihal']);
        
        // Check if admin is querying for specific user
        if ($user->isAdmin() && $request->filled('user_id')) {
            $query->forUser($request->user_id);
        } else {
            // Regular users see only their own history
            $query->forUser($user->id_user);
        }
        
        // Apply filters
        if ($request->filled('action_type')) {
            $query->action($request->action_type);
        }
        
        if ($request->filled('date_from')) {
            $query->where('created_at', '>=', $request->date_from);
        }
        
        if ($request->filled('date_to')) {
            $query->where('created_at', '<=', $request->date_to . ' 23:59:59');
        }
        
        // Order by most recent first
        $query->orderBy('created_at', 'desc');
        
        $history = $query->paginate($perPage);
        
        return response()->json([
            'status' => 200,
            'data' => $history->items(),
            'meta' => [
                'current_page' => $history->currentPage(),
                'per_page' => $history->perPage(),
                'total' => $history->total(),
                'last_page' => $history->lastPage(),
            ],
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
