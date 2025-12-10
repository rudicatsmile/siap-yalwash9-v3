<?php

namespace Tests\Feature;

use App\Models\TipeSurat;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TipeSuratDropdownTest extends TestCase
{
    use RefreshDatabase;

    protected function createAdmin(): User
    {
        return User::create([
            'username' => 'admin',
            'password' => 'admin123',
            'nama_lengkap' => 'Administrator',
            'jabatan' => 'Admin',
            'role' => 'admin',
            'instansi' => '10',
            'email' => 'admin@example.com',
            'level' => '1',
            'kode_user' => 'ADMIN001',
        ]);
    }

    public function test_requires_authorized_role(): void
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

        $resp = $this->getJson('/api/dropdown/tipe-surat');
        $resp->assertStatus(403);
    }

    public function test_admin_can_access_and_get_data(): void
    {
        $admin = $this->createAdmin();
        Sanctum::actingAs($admin);

        TipeSurat::create(['klasifikasi_surat_keluar' => 'Umum', 'kode' => 'U-01']);
        TipeSurat::create(['klasifikasi_surat_keluar' => 'Rahasia', 'kode' => 'R-02']);

        $resp = $this->getJson('/api/dropdown/tipe-surat');

        $resp->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [['id', 'klasifikasi', 'kode']]
            ]);
    }
}

