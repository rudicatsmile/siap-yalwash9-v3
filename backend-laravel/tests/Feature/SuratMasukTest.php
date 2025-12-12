<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SuratMasukTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_create_surat_masuk_success(): void
    {
        $user = User::create([
            'username' => 'tester',
            'password' => 'password',
            'nama_lengkap' => 'Tester Satu',
            'role' => 'admin',
            'instansi' => 'INST-001',
            'kode_user' => 'USR-001',
        ]);

        Sanctum::actingAs($user);

        $payload = [
            'no_asal' => 'DOC-123',
            'tgl_surat' => now()->toDateString(),
            'pengirim' => 'Unit A',
            'penerima' => 'Unit B',
            'perihal' => 'Pengajuan Berkas',
            'sifat' => 'Biasa',
            'kategori_surat' => 'Dokumen',
            'klasifikasi_surat' => 'Internal',
            'status' => 'Dokumen',
        ];

        $res = $this->postJson('/api/surat-masuk', $payload);

        $res->assertStatus(201)
            ->assertJsonStructure(['status', 'message', 'data' => ['id_sm', 'no_surat']]);

        $this->assertDatabaseHas('tbl_sm', [
            'no_asal' => 'DOC-123',
            'pengirim' => 'Unit A',
            'kategori_surat' => 'Dokumen',
        ]);
    }

    public function test_validation_error_when_missing_required_fields(): void
    {
        $user = User::create([
            'username' => 'tester2',
            'password' => 'password',
            'nama_lengkap' => 'Tester Dua',
            'role' => 'admin',
            'instansi' => 'INST-001',
            'kode_user' => 'USR-002',
        ]);

        Sanctum::actingAs($user);

        $res = $this->postJson('/api/surat-masuk', []);

        $res->assertStatus(422)
            ->assertJsonValidationErrors(['no_asal', 'tgl_surat', 'pengirim', 'penerima', 'perihal', 'sifat', 'kategori_surat', 'klasifikasi_surat', 'status']);
    }
}

