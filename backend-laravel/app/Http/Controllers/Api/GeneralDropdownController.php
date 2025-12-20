<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class GeneralDropdownController extends Controller
{
    public function dropdown(Request $request): JsonResponse
    {
        try {
            $table = $request->input('table_name');
            if (!is_string($table) || trim($table) === '') {
                return response()->json([
                    'success' => false,
                    'message' => 'Parameter table_name wajib diisi',
                ], 400);
            }

            if (!preg_match('/^[A-Za-z0-9_]+$/', $table)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Nama tabel tidak valid',
                ], 400);
            }

            if (!Schema::hasTable($table)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tabel tidak ditemukan',
                ], 404);
            }

            foreach (['kode', 'deskripsi', 'keterangan'] as $col) {
                if (!Schema::hasColumn($table, $col)) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Struktur tabel tidak kompatibel',
                    ], 404);
                }
            }

            $limit = (int) ($request->input('limit', 10));
            if ($limit <= 0) {
                $limit = 10;
            }
            $limit = min($limit, 1000);

            $query = DB::table($table)->select(['kode', 'deskripsi', 'keterangan']);

            if ($table === 'm_tujuan_disposisi' && Schema::hasColumn($table, 'urut')) {
                $query->orderBy('urut');
            }

            if ($request->filled('status') && Schema::hasColumn($table, 'status')) {
                $query->where('status', 1);
            }

            if ($request->filled('search')) {
                $s = $request->input('search');
                $query->where('deskripsi', 'like', "%$s%");
            }

            // Filter specific for m_kategori_formulir based on user code
            if ($table === 'm_kategori_formulir') {
                $user = $request->user();
                if ($user && in_array($user->kode_user, ['YS-01-PMP-001', 'YS-01-WPM-001', 'YS-01-KHR-001'])) {
                    $query->whereIn('kode', ['Memo', 'Koordinasi']);
                } else {
                    $query->whereNotIn('kode', ['Memo', 'Koordinasi']);
                }
            }

            $total = (clone $query)->count();
            $rows = $query->limit($limit)->get();

            return response()->json([
                'success' => true,
                'data' => $rows->map(function ($r) {
                    return [
                        'kode' => (string) $r->kode,
                        'deskripsi' => (string) $r->deskripsi,
                        'keterangan' => $r->keterangan,
                    ];
                }),
                'pagination' => [
                    'total' => $total,
                    'limit' => $limit,
                ],
            ], 200);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => config('app.debug') ? $e->getMessage() : 'Terjadi kesalahan pada server',
            ], 500);
        }
    }
}

