<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TindakanSegera;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class TindakanSegeraController extends Controller
{
    public function dropdown(Request $request): JsonResponse
    {
        try {
            $search = $request->string('search')->toString();
            $page = (int) $request->input('page', 0);
            $perPage = (int) $request->input('per_page', 1000);
            if ($perPage <= 0) {
                $perPage = 1000;
            }
            if ($perPage > 1000) {
                $perPage = 1000;
            }

            $useCache = empty($search) && $page === 0 && $perPage === 1000;

            if ($useCache) {
                $cached = Cache::remember('dropdown:tindakan-segera:v1', 300, function () {
                    return TindakanSegera::query()
                        ->select(['id', 'kode', 'deskripsi', 'keterangan'])
                        ->orderBy('id', 'asc')
                        ->limit(1000)
                        ->get();
                });

                $data = $cached->map(function ($row) {
                    return [
                        'value' => (string) $row->id,
                        'label' => trim(($row->kode ?? '') . ' - ' . ($row->deskripsi ?? '')),
                        'keterangan' => $row->keterangan,
                    ];
                });

                return response()->json([
                    'success' => true,
                    'data' => $data,
                    'message' => 'Data tindakan segera berhasil diambil',
                ], 200);
            }

            $query = TindakanSegera::query()
                ->select(['id', 'kode', 'deskripsi', 'keterangan'])
                ->orderBy('id', 'asc');

            if (!empty($search)) {
                $query->where(function ($q) use ($search) {
                    $q->where('kode', 'like', "%{$search}%")
                        ->orWhere('deskripsi', 'like', "%{$search}%");
                });
            }

            if ($page > 0) {
                $rows = $query->paginate($perPage, ['*'], 'page', $page);
                $items = collect($rows->items());
            } else {
                $rows = $query->limit($perPage)->get();
                $items = $rows;
            }

            $data = $items->map(function ($row) {
                return [
                    'value' => (string) $row->id,
                    'label' => trim(($row->kode ?? '') . ' - ' . ($row->deskripsi ?? '')),
                    'keterangan' => $row->keterangan,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $data,
                'message' => 'Data tindakan segera berhasil diambil',
            ], 200);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'data' => [],
                'message' => 'Terjadi kesalahan pada server',
            ], 500);
        }
    }
}

