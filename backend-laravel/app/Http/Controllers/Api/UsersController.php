<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityHistory;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UsersController extends Controller
{
    public function dropdown(Request $request): JsonResponse
    {
        try {
            $limit = (int) ($request->input('limit', 50));
            if ($limit <= 0) {
                $limit = 50;
            }
            $limit = min($limit, 1000);

            $query = User::query()
                ->select(['id_user as id', 'username', 'nama_lengkap', 'jabatan']);

            if ($request->filled('search')) {
                $s = $request->input('search');
                $query->where(function ($q) use ($s) {
                    $q->where('username', 'like', "%$s%")
                        ->orWhere('nama_lengkap', 'like', "%$s%");
                });
            }

            $kodeUserInput = $request->filled('kode_user')
                ? strtoupper(trim((string) $request->input('kode_user')))
                : null;
            if ($kodeUserInput && in_array($kodeUserInput, ['YS', 'MN', 'SK'], true)) {
                $query->where('kode_user', 'like', $kodeUserInput . '%');
            }

            if ($kodeUserInput === 'YS') {
                $query->orderBy('level_pimpinan', 'asc');
            } else {
                $query->orderBy('nama_lengkap', 'asc');
            }

            // Basic pagination: support ?page=, default page=1
            $page = (int) $request->input('page', 1);
            if ($page > 0) {
                $rows = $query->paginate($limit, ['*'], 'page', $page);
                $items = collect($rows->items());
            } else {
                $items = $query->limit($limit)->get();
            }

            $data = $items->map(function ($u) {
                return [
                    'id' => (int) $u->id,
                    'username' => (string) $u->username,
                    'nama_lengkap' => (string) $u->nama_lengkap,
                    'jabatan' => $u->jabatan,
                ];
            });

            // Log activity (if authenticated)
            if ($request->user()) {
                ActivityHistory::log(
                    userId: $request->user()->id_user,
                    action: 'users_dropdown',
                    description: 'Fetch users dropdown',
                    metadata: [
                        'search' => $request->input('search'),
                        'limit' => $limit,
                        'page' => $page,
                    ]
                );
            }

            return response()->json([
                'success' => true,
                'data' => $data,
                'message' => null,
            ], 200);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'data' => [],
                'message' => config('app.debug') ? $e->getMessage() : 'Terjadi kesalahan pada server',
            ], 500);
        }
    }
}
