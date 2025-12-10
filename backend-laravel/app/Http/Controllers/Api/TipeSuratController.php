<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TipeSurat;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class TipeSuratController extends Controller
{
    public function dropdown(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            if (!$user || (!method_exists($user, 'isAdmin') || !$user->isAdmin()) && (!method_exists($user, 'isPimpinan') || !$user->isPimpinan())) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tidak diizinkan',
                    'data' => [],
                ], 403);
            }

            $query = TipeSurat::query()
                ->orderBy('klasifikasi_surat_keluar', 'asc')
                ->select(['id_tipe_surat', 'klasifikasi_surat_keluar', 'kode']);

            if ($request->filled('search')) {
                $s = $request->input('search');
                $query->where(function ($q) use ($s) {
                    $q->where('klasifikasi_surat_keluar', 'like', "%$s%")
                        ->orWhere('kode', 'like', "%$s%");
                });
            }

            if ($request->filled('limit') && is_numeric($request->input('limit'))) {
                $query->limit((int) $request->input('limit'));
            }

            $rows = $query->limit(1000)->get();

            $data = $rows->map(function ($r) {
                return [
                    'id' => (int) $r->id_tipe_surat,
                    'klasifikasi' => (string) $r->klasifikasi_surat_keluar,
                    'kode' => (string) $r->kode,
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'Data tipe surat berhasil diambil',
                'data' => $data,
            ], 200);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server',
                'data' => [],
            ], 500);
        }
    }
}
