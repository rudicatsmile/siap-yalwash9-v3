<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class SuratMasukChildController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'id_sm' => ['required', 'integer', Rule::exists('tbl_sm', 'id_sm')],
            'no_asal' => ['required', 'string'],
            'tgl_agenda_rapat' => ['required', 'date_format:Y-m-d'],
            'jam_rapat' => ['required', 'date_format:H:i:s'],
            'bahasan_rapat' => ['required', 'string'],
            'pimpinan_rapat' => ['required', 'string'],
            'peserta_rapat' => ['required', 'string'],
            'id_status_rapat' => ['required', 'integer', 'not_in:1'],
        ], [
            'id_status_rapat.not_in' => 'id_status_rapat tidak boleh bernilai 1',
            'tgl_agenda_rapat.date_format' => 'Format tgl_agenda_rapat harus Y-m-d',
            'jam_rapat.date_format' => 'Format jam_rapat harus H:i:s',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 400);
        }

        $data = $validator->validated();

        if ((int) $data['id_status_rapat'] === 1) {
            return response()->json([
                'success' => false,
                'message' => 'Insert ditolak karena id_status_rapat = 1',
            ], 400);
        }

        try {
            $row = DB::transaction(function () use ($data) {
                $now = now();
                $insert = [
                    'id_sm' => (int) $data['id_sm'],
                    'no_asal' => (string) $data['no_asal'],
                    'tgl_agenda_rapat' => (string) $data['tgl_agenda_rapat'],
                    'jam_rapat' => (string) $data['jam_rapat'],
                    'bahasan_rapat' => (string) $data['bahasan_rapat'],
                    'pimpinan_rapat' => (string) $data['pimpinan_rapat'],
                    'peserta_rapat' => (string) $data['peserta_rapat'],
                    'id_status_rapat' => (int) $data['id_status_rapat'],
                    'created_at' => $now,
                    'updated_at' => $now,
                ];

                $id = DB::table('tbl_sm_child')->insertGetId($insert, 'id_sm_child');
                return DB::table('tbl_sm_child')->where('id_sm_child', $id)->first();
            });

            return response()->json([
                'success' => true,
                'message' => 'Berhasil menambahkan data tbl_sm_child',
                'data' => $row,
            ], 201);
        } catch (\Throwable $e) {
            Log::error('Insert tbl_sm_child failed', [
                'error' => $e->getMessage(),
                'payload' => $request->all(),
                'user_id' => $request->user()?->getAuthIdentifier(),
            ]);

            return response()->json([
                'success' => false,
                'message' => config('app.debug') ? $e->getMessage() : 'Gagal menambahkan data tbl_sm_child',
            ], 500);
        }
    }
}
