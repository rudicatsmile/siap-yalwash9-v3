<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreDocumentRequest extends FormRequest
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
            'no_asal' => ['required', 'string', 'max:100'],
            'tgl_surat' => ['required', 'date', 'before_or_equal:today'],
            'pengirim' => ['required', 'string', 'max:255'],
            'penerima' => ['required', 'string', 'max:255'],
            'perihal' => ['required', 'string', 'min:10'],
            'sifat' => ['required', 'in:Segera,Biasa,Rahasia'],
            'kategori_surat' => ['required', 'string', 'max:100'],
            'klasifikasi_surat' => ['required', 'string', 'max:100'],
            'kategori_kode' => ['nullable', 'string', 'max:100'],
            'kategori_berkas' => ['nullable', 'string', 'max:100'],
            'kode_berkas' => ['nullable', 'string', 'max:100'],
            'lampiran' => ['nullable', 'string', 'max:255'],
            'token_lampiran' => ['nullable', 'string', 'max:100'],
        ];
    }

    /**
     * Get custom error messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'no_asal.required' => 'Original document number is required',
            'tgl_surat.required' => 'Document date is required',
            'tgl_surat.before_or_equal' => 'Document date cannot be in the future',
            'pengirim.required' => 'Sender information is required',
            'penerima.required' => 'Recipient information is required',
            'perihal.required' => 'Subject/matter is required',
            'perihal.min' => 'Subject must be at least 10 characters',
            'sifat.required' => 'Document priority is required',
            'sifat.in' => 'Invalid priority value',
        ];
    }
}
