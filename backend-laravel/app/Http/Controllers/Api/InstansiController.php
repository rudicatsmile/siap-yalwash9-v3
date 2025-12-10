<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Instansi;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class InstansiController extends Controller
{
    public function dropdown(Request $request): JsonResponse
    {
        try {
            $query = Instansi::query()
                ->orderBy('m_instansi.id', 'asc')
                ->limit(1000)
                ->select([
                    'm_instansi.id',
                    'm_instansi.kode',
                    'm_instansi.deskripsi',
                    'm_instansi.keterangan',
                    'm_instansi.telp',
                    'm_instansi.kode_surat',
                ]);

            $data = $query->get();

            return response()->json([
                'success' => true,
                'data' => $data,
                'error' => null,
            ], 200);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'data' => [],
                'error' => config('app.debug') ? ($e->getMessage()) : 'Terjadi kesalahan pada server',
            ], 500);
        }
    }
}
