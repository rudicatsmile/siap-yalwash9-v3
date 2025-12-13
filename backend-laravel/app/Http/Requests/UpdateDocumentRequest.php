<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateDocumentRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true; // Authorization handled in controller
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'no_asal' => ['sometimes', 'string', 'max:100'],
            'tgl_surat' => ['sometimes', 'date', 'before_or_equal:today'],
            'pengirim' => ['sometimes', 'string', 'max:255'],
            'penerima' => ['sometimes', 'string', 'max:255'],
            'perihal' => ['sometimes', 'string', 'min:10'],
            'sifat' => ['sometimes', 'in:Segera,Biasa,Rahasia'],
            'kategori_surat' => ['sometimes', 'string', 'max:100'],
            'klasifikasi_surat' => ['sometimes', 'string', 'max:100'],
            'kategori_berkas' => ['sometimes', 'string', 'max:100'],
            'kode_berkas' => ['sometimes', 'string', 'max:100'],
            'lampiran' => ['nullable', 'string', 'max:255'],
            'token_lampiran' => ['nullable', 'string', 'max:100'],
        ];
    }
}
