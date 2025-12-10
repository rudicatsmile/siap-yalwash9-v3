<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TujuanDisposisi;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class TujuanDisposisiController extends Controller
{
    /**
     * Get list of active disposition goals (tujuan disposisi).
     *
     * @return JsonResponse
     */
    public function index(): JsonResponse
    {
        try {
            $tujuanDisposisi = TujuanDisposisi::with('user:id_user,username')
                ->where('status', '1')
                ->orderBy('urut', 'asc')
                ->limit(1000)
                ->get()
                ->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'kode' => $item->kode,
                        'deskripsi' => $item->deskripsi,
                        'keterangan' => $item->keterangan,
                        'telp' => $item->telp,
                        'urut' => $item->urut,
                        // Get username from relationship, fallback to null or empty string if user not found
                        'username' => $item->user ? $item->user->username : null,
                        'status' => $item->status,
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => $tujuanDisposisi,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat mengambil data tujuan disposisi',
                'error' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }
}
