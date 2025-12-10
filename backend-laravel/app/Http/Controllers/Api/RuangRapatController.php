<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RuangRapat;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class RuangRapatController extends Controller
{
    /**
     * Get dropdown data for meeting rooms.
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function dropdown(Request $request): JsonResponse
    {
        try {
            $query = RuangRapat::query()
                ->select(['id', 'kode', 'deskripsi', 'keterangan', 'telp'])
                ->orderBy('id', 'asc');

            // Filtering by search term (kode or deskripsi)
            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $query->where(function ($q) use ($search) {
                    $q->where('kode', 'like', "%{$search}%")
                        ->orWhere('deskripsi', 'like', "%{$search}%");
                });
            }

            // Limit results if requested
            if ($request->has('limit') && is_numeric($request->limit)) {
                $query->limit((int) $request->limit);
            }

            $data = $query->get();

            return response()->json([
                'status' => 'success',
                'code' => 200,
                'data' => $data,
                'message' => 'Data ruang rapat berhasil diambil'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'code' => 500,
                'data' => [],
                'message' => config('app.debug') ? $e->getMessage() : 'Terjadi kesalahan pada server'
            ], 500);
        }
    }
}
