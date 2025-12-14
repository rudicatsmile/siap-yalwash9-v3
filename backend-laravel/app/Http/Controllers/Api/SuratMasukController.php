<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSuratMasukRequest;
use App\Models\Document;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

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
                $data['tgl_ns'] = $data['tgl_ns'] ?? now()->toDateString();
                $data['tgl_sm'] = $data['tgl_sm'] ?? now()->toDateString();
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

    /**
     * Upload lampiran file dan simpan metadata ke tabel tbl_lampiran.
     *
     * Menerima file multipart dan parameter:
     * - no_surat: string (wajib)
     * - tgl_surat: date (wajib, format Y-m-d)
     *
     * token_lampiran di-generate: md5("{id_user}-{no_surat_part1}-{tgl_surat_ymd}")
     * nama_berkas diambil dari original filename, ukuran dari size file.
     */
    public function uploadLampiran(Request $request): JsonResponse
    {
        $user = $request->user();

        try {
            $validated = $request->validate([
                'file' => 'required|file|mimes:jpg,jpeg,png,webp,pdf,doc,docx,xls,xlsx|max:10240',
                'no_surat' => 'required|string',
                'tgl_surat' => 'required|date',
            ]);

            $file = $request->file('file');
            $originalName = $file->getClientOriginalName();
            $size = $file->getSize();
            $noSurat = $validated['no_surat'];
            $tglSurat = date('Y-m-d', strtotime($validated['tgl_surat']));

            $part1 = explode('/', $noSurat)[0] ?? $noSurat;
            $token = md5(($user->id_user ?? '0') . '-' . $part1 . '-' . $tglSurat);

            $sanitized = preg_replace('/[^A-Za-z0-9._-]/', '_', $originalName);
            $dir = 'lampiran/' . date('Y') . '/' . date('m') . '/' . ($user->id_user ?? '0');
            $ext = strtolower($file->getClientOriginalExtension());
            $filename = uniqid() . '-' . $sanitized;
            $target = $dir . '/' . $filename;
            if (in_array($ext, ['jpg', 'jpeg', 'png', 'webp'])) {
                try {
                    $tmp = $file->getRealPath();
                    if (in_array($ext, ['jpg', 'jpeg'])) {
                        $img = @imagecreatefromjpeg($tmp);
                        ob_start();
                        @imagejpeg($img, null, 85);
                        $data = ob_get_clean();
                        if ($data && strlen($data) > 0) {
                            \Illuminate\Support\Facades\Storage::disk('public')->put($target, $data);
                        } else {
                            $path = $file->store($dir, 'public');
                            $target = $path;
                        }
                    } elseif ($ext === 'png') {
                        $img = @imagecreatefrompng($tmp);
                        ob_start();
                        @imagepng($img, null, 6);
                        $data = ob_get_clean();
                        if ($data && strlen($data) > 0) {
                            \Illuminate\Support\Facades\Storage::disk('public')->put($target, $data);
                        } else {
                            $path = $file->store($dir, 'public');
                            $target = $path;
                        }
                    } else {
                        $path = $file->store($dir, 'public');
                        $target = $path;
                    }
                } catch (\Throwable $e) {
                    $path = $file->store($dir, 'public');
                    $target = $path;
                }
            } else {
                $path = $file->store($dir, 'public');
                $target = $path;
            }
            $id = DB::table('tbl_lampiran')->insertGetId([
                'no_surat' => $noSurat,
                'token_lampiran' => $token,
                'nama_berkas' => $originalName,
                'ukuran' => $size,
            ]);

            Log::info('Lampiran uploaded', [
                'user_id' => $user->id_user ?? null,
                'no_surat' => $noSurat,
                'id_lampiran' => $id,
                'path' => $target,
            ]);

            return response()->json([
                'status' => 201,
                'message' => 'Lampiran berhasil diunggah',
                'data' => [
                    'id' => $id,
                    'url' => asset('storage/' . $target),
                ],
                'timestamp' => now()->toIso8601String(),
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status' => 422,
                'message' => 'Validasi gagal',
                'errors' => $e->errors(),
                'timestamp' => now()->toIso8601String(),
            ], 422);
        } catch (\Throwable $e) {
            Log::error('Lampiran upload failed', [
                'error' => $e->getMessage(),
                'trace' => config('app.debug') ? $e->getTraceAsString() : null,
            ]);
            return response()->json([
                'status' => 500,
                'message' => 'Gagal mengunggah lampiran',
                'error' => config('app.debug') ? $e->getMessage() : null,
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }
}
