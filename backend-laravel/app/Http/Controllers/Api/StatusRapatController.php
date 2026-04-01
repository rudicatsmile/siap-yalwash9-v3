<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class StatusRapatController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $table = 'tbl_status_rapat';
            if (!Schema::hasTable($table)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tabel tidak ditemukan',
                ], 404);
            }

            foreach (['id_status', 'nama_status'] as $col) {
                if (!Schema::hasColumn($table, $col)) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Struktur tabel tidak kompatibel',
                    ], 404);
                }
            }

            $query = DB::table($table)->select(['id_status', 'nama_status']);

            if (Schema::hasColumn($table, 'status')) {
                $query->where('status', 1);
            }

            if ($request->filled('search')) {
                $s = $request->input('search');
                $query->where('nama_status', 'like', "%$s%");
            }

            $rows = $query->get();

            return response()->json([
                'success' => true,
                'data' => $rows->map(function ($r) {
                    return [
                        'id_status' => (string) $r->id_status,
                        'nama_status' => (string) $r->nama_status,
                    ];
                }),
            ], 200);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => config('app.debug') ? $e->getMessage() : 'Terjadi kesalahan pada server',
            ], 500);
        }
    }
}
