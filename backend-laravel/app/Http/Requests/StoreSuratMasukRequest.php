<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreSuratMasukRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_sm' => ['sometimes', 'integer'],
            'no_surat' => ['sometimes', 'string', 'max:50'],
            'tgl_ns' => ['sometimes', 'date'],
            'no_asal' => ['required', 'string', 'max:100'],
            'tgl_no_asal' => ['nullable', 'date'],
            'tgl_no_asal2' => ['nullable', 'date'],
            // 'tgl_surat' => ['required', 'date', 'before_or_equal:today'],
            'tgl_surat' => ['required', 'date'],
            'pengirim' => ['required', 'string', 'max:255'],
            'penerima' => ['required', 'string', 'max:255'],
            'perihal' => ['required', 'string', 'min:5'],
            'token_lampiran' => ['nullable', 'string', 'max:100'],
            'token_lampiran_tu' => ['nullable', 'string', 'max:100'],
            'bagian' => ['nullable', 'string', 'max:100'],
            'disposisi' => ['nullable', 'string'],
            'id_user' => ['sometimes', 'integer'],
            'kode_user' => ['sometimes', 'string', 'max:100'],
            'kode_user_approved' => ['nullable', 'string', 'max:100'],
            'id_user_approved' => ['nullable', 'integer'],
            'id_instansi' => ['sometimes', 'string', 'max:100'],
            'id_instansi_approved' => ['nullable', 'string', 'max:100'],
            'id_user_disposisi_leader' => ['nullable', 'integer'],
            'tgl_sm' => ['sometimes', 'date'],
            'lampiran' => ['nullable', 'string', 'max:255'],
            'status' => ['required', 'string', 'max:100'],
            'sifat' => ['required', 'in:Segera,Biasa,Rahasia'],
            'dibaca' => ['nullable', 'boolean'],
            'dibaca_pimpinan' => ['nullable', 'boolean'],
            'kode_user_pimpinan' => ['nullable', 'string', 'max:100'],
            'tgl_ajuan' => ['nullable', 'date'],
            'tgl_ajuan_delegate' => ['nullable', 'date'],
            'segera' => ['nullable', 'boolean'],
            'biasa' => ['nullable', 'boolean'],
            'catatan' => ['nullable', 'string'],
            'tgl_disposisi' => ['nullable', 'date'],
            'tgl_approved' => ['nullable', 'date'],
            'catatan_koreksi' => ['nullable', 'string'],
            'is_notes_pimpinan' => ['nullable', 'boolean'],
            'status_tu' => ['nullable', 'boolean'],
            'status_instansi' => ['nullable', 'boolean'],
            'tgl_delegasi_rapat' => ['nullable', 'date'],
            'tgl_agenda_rapat' => ['nullable', 'date'],
            'tgl_hasil_rapat' => ['nullable', 'date'],
            'delegasi_pimpinan' => ['nullable', 'boolean'],
            'disposisi_rapat' => ['nullable', 'string'],
            'delegasi_tu' => ['nullable', 'string', 'max:100'],
            'ruang_rapat' => ['nullable', 'string', 'max:100'],
            'penanda_tangan_rapat' => ['nullable', 'string', 'max:255'],
            'tembusan_rapat' => ['nullable', 'string'],
            'jam_rapat' => ['nullable', 'string', 'max:20'],
            'bahasan_rapat' => ['nullable', 'string'],
            'pimpinan_rapat' => ['nullable', 'string', 'max:255'],
            'peserta_rapat' => ['nullable', 'string'],
            'ditujukan' => ['nullable', 'string'],
            'instruksi_kerja' => ['nullable', 'string'],
            'disposisi_memo' => ['nullable', 'string'],
            'kategori_berkas' => ['nullable', 'string', 'max:100'],
            'kategori_undangan' => ['nullable', 'string', 'max:100'],
            'kategori_laporan' => ['nullable', 'string', 'max:100'],
            'id_status_rapat' => ['nullable', 'integer'],
            'kode_user_ditujukan_memo' => ['nullable', 'string', 'max:100'],
            'kategori_surat' => ['required', 'string', 'max:100'],
            'klasifikasi_surat' => ['required', 'string', 'max:100'],
            'kode_berkas' => ['required', 'string', 'max:30'],
            'kategori_kode' => ['required', 'string', 'max:100'],
            'disposisi_ktu_leader' => ['nullable', 'string', 'max:100'],
            'created_at' => ['sometimes', 'date'],
            'updated_at' => ['sometimes', 'date'],
            'deleted_at' => ['nullable', 'date'],
        ];
    }

    public function messages(): array
    {
        return [
            'no_asal.required' => 'Nomor asal wajib diisi',
            'tgl_surat.required' => 'Tanggal surat wajib diisi',
            'pengirim.required' => 'Pengirim wajib diisi',
            'penerima.required' => 'Penerima wajib diisi',
            'perihal.required' => 'Perihal wajib diisi',
            'sifat.required' => 'Sifat dokumen wajib diisi',
            'kategori_surat.required' => 'Kategori surat wajib diisi',
            'klasifikasi_surat.required' => 'Klasifikasi surat wajib diisi',
        ];
    }
}

