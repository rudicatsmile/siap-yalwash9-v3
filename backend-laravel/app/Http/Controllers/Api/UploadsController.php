<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class UploadsController extends Controller
{
    public function uploadTemp(Request $request): JsonResponse
    {
        $user = $request->user();
        try {
            $validated = $request->validate([
                'file' => 'required|file|mimes:jpg,jpeg,png,webp,pdf,doc,docx,xls,xlsx|max:10240',
            ]);
            $file = $request->file('file');
            $originalName = $file->getClientOriginalName();
            $size = $file->getSize();
            $ext = strtolower($file->getClientOriginalExtension());
            $sanitized = preg_replace('/[^A-Za-z0-9._-]/', '_', $originalName);
            $dir = 'uploads/temp/' . date('Y') . '/' . date('m') . '/' . ($user->id_user ?? '0');
            $filename = uniqid() . '-' . $sanitized;
            //$target = $dir . '/' . $filename;
            $target = $dir . '/' . $originalName;
            $blocked = ['application/x-msdownload', 'application/x-msdos-program'];
            $mime = $file->getMimeType();
            if (in_array($mime, $blocked, true)) {
                return response()->json([
                    'status' => 422,
                    'message' => 'Tipe berkas tidak diizinkan',
                    'timestamp' => now()->toIso8601String(),
                ], 422);
            }
            if (in_array($ext, ['jpg', 'jpeg', 'png'])) {
                try {
                    $tmp = $file->getRealPath();
                    if (in_array($ext, ['jpg', 'jpeg'])) {
                        $img = @imagecreatefromjpeg($tmp);
                        ob_start();
                        @imagejpeg($img, null, 85);
                        $data = ob_get_clean();
                        if ($data && strlen($data) > 0) {
                            Storage::disk('public')->put($target, $data);
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
                            Storage::disk('public')->put($target, $data);
                        } else {
                            $path = $file->store($dir, 'public');
                            $target = $path;
                        }
                    }
                } catch (\Throwable $e) {
                    $path = $file->store($dir, 'public');
                    $target = $path;
                }
            } else {
                $path = $file->store($dir, 'public');
                $target = $path;
            }
            $id = sha1($target);
            Log::info('Temp upload', [
                'user_id' => $user->id_user ?? null,
                'path' => $target,
                'size' => $size,
                'mime' => $mime,
                'name' => $originalName,
            ]);
            return response()->json([
                'status' => 201,
                'message' => 'Berkas terunggah',
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
            Log::error('Temp upload failed', [
                'error' => $e->getMessage(),
            ]);
            return response()->json([
                'status' => 500,
                'message' => 'Gagal mengunggah berkas',
                'timestamp' => now()->toIso8601String(),
            ], 500);
        }
    }
}

