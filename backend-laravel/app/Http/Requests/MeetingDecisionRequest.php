<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MeetingDecisionRequest extends FormRequest
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
            'disposisi_rapat' => ['required', 'string', 'min:10'],
            'tgl_hasil_rapat' => ['nullable', 'date', 'before_or_equal:today'],
            'status' => ['nullable', 'in:Selesai'],
            'catatan' => ['nullable', 'string'],
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
            'disposisi_rapat.required' => 'Meeting decision is required',
            'disposisi_rapat.min' => 'Meeting decision must be at least 10 characters',
            'tgl_hasil_rapat.before_or_equal' => 'Decision date cannot be in the future',
        ];
    }
}
