<?php

namespace Tests\Feature;

use App\Models\Instansi;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class InstansiDropdownTest extends TestCase
{
    use RefreshDatabase;

    public function test_requires_authentication(): void
    {
        $resp = $this->getJson('/api/instansi/dropdown');
        $resp->assertStatus(401);
    }

    public function test_authenticated_user_can_get_data(): void
    {
        $user = User::create([
            'username' => 'user1',
            'password' => 'password',
            'nama_lengkap' => 'User Satu',
            'jabatan' => 'Staff',
            'role' => 'user',
            'instansi' => '03',
            'email' => 'user1@example.com',
            'level' => '1',
            'kode_user' => 'USR001',
        ]);

        Sanctum::actingAs($user);

        Instansi::create([
            'kode' => 'INS-01',
            'deskripsi' => 'Instansi A',
            'keterangan' => 'Keterangan A',
            'telp' => '08123456789',
            'id_user' => null,
            'kode_surat' => 'KS-01',
        ]);

        $resp = $this->getJson('/api/instansi/dropdown');
        $resp->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'data', 'error']);
    }
}

