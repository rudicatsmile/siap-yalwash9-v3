<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UsersDropdownTest extends TestCase
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

    public function test_requires_authentication(): void
    {
        $resp = $this->getJson('/api/users/dropdown');
        $resp->assertStatus(401);
    }

    public function test_success_with_authenticated_user(): void
    {
        $admin = $this->createAdmin();
        Sanctum::actingAs($admin);

        User::create([
            'username' => 'jdoe',
            'password' => 'secret',
            'nama_lengkap' => 'John Doe',
            'jabatan' => 'Staff',
            'role' => 'user',
            'instansi' => '03',
            'email' => 'john@example.com',
            'level' => '1',
            'kode_user' => 'USR001',
        ]);

        $resp = $this->getJson('/api/users/dropdown?limit=50');
        $resp->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'data' => [['id', 'username', 'nama_lengkap', 'jabatan']], 'message']);
    }

    public function test_search_filters_results(): void
    {
        $admin = $this->createAdmin();
        Sanctum::actingAs($admin);

        User::create([
            'username' => 'alice',
            'password' => 'secret',
            'nama_lengkap' => 'Alice Wonder',
            'jabatan' => 'Staff',
            'role' => 'user',
            'instansi' => '03',
            'email' => 'alice@example.com',
            'level' => '1',
            'kode_user' => 'USR002',
        ]);
        User::create([
            'username' => 'bob',
            'password' => 'secret',
            'nama_lengkap' => 'Bob Builder',
            'jabatan' => 'Staff',
            'role' => 'user',
            'instansi' => '03',
            'email' => 'bob@example.com',
            'level' => '1',
            'kode_user' => 'USR003',
        ]);

        $resp = $this->getJson('/api/users/dropdown?search=Alice');
        $resp->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonCount(1, 'data');
    }
}

