<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSuratMasukRequest;
use App\Models\Document;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class SuratMasukController extends Controller
{
    public function store(StoreSuratMasukRequest $request): JsonResponse
    {
        $user = $request->user();

        try {
            $document = DB::transaction(function () use ($request, $user) {
                $data = $request->validated();

                // Generate no_surat if not provided
                if (empty($data['no_surat'])) {
                    $last = Document::query()
                        ->orderByRaw("CAST(TRIM(LEADING '0' FROM no_surat) AS UNSIGNED) DESC")
                        ->value('no_surat');
                    $numeric = $last ? (int) ltrim($last, '0') : 0;
                    $next = str_pad((string) ($numeric + 1), $last ? strlen($last) : 6, '0', STR_PAD_LEFT);
                    $data['no_surat'] = $next;
                }

                // Default dates and ownership fields
                // $data['tgl_ns'] = $data['tgl_ns'] ?? now()->toDateString();
                // $data['tgl_sm'] = $data['tgl_sm'] ?? now()->toDateString();
                $data['id_user'] = $user->id_user;
                $data['kode_user'] = $user->kode_user;
                $data['id_instansi'] = $user->instansi;


                // Create record
                return Document::create($data);
            });

            return response()->json([
                'status' => 201,
                'message' => 'Surat masuk berhasil dibuat',
                'data' => $document,
                'timestamp' => now()->toIso8601String(),
            ], 201);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Gagal membuat surat masuk',
                'error' => $e->getMessage(),
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }
}

