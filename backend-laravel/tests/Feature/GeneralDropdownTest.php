<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class GeneralDropdownTest extends TestCase
{
    use RefreshDatabase;

    protected function auth(): User
    {
        $user = User::create([
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
        Sanctum::actingAs($user);
        return $user;
    }

    public function test_requires_authentication(): void
    {
        $resp = $this->getJson('/api/general/dropdown');
        $resp->assertStatus(401);
    }

    public function test_missing_table_name_returns_400(): void
    {
        $this->auth();
        $resp = $this->getJson('/api/general/dropdown');
        $resp->assertStatus(400);
    }

    public function test_table_not_found_returns_404(): void
    {
        $this->auth();
        $resp = $this->getJson('/api/general/dropdown?table_name=unknown_table');
        $resp->assertStatus(404);
    }

    public function test_success_with_tindakan_segera(): void
    {
        $this->auth();
        if (!Schema::hasTable('m_tindakan_segera')) {
            Schema::create('m_tindakan_segera', function ($t) {
                $t->id();
                $t->string('kode')->unique();
                $t->text('deskripsi');
                $t->text('keterangan')->nullable();
                $t->integer('status')->default(1);
                $t->timestamps();
            });
        }

        DB::table('m_tindakan_segera')->insert([
            'kode' => 'TS-01',
            'deskripsi' => 'Segera',
            'keterangan' => null,
            'status' => 1
        ]);

        $resp = $this->getJson('/api/general/dropdown?table_name=m_tindakan_segera&limit=10');
        $resp->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'data' => [['kode', 'deskripsi', 'keterangan']], 'pagination' => ['total', 'limit']]);
    }

    public function test_search_filters_deskripsi(): void
    {
        $this->auth();
        if (!Schema::hasTable('m_tindakan_segera')) {
            Schema::create('m_tindakan_segera', function ($t) {
                $t->id();
                $t->string('kode')->unique();
                $t->text('deskripsi');
                $t->text('keterangan')->nullable();
                $t->timestamps();
            });
        }

        DB::table('m_tindakan_segera')->insert([
            ['kode' => 'A1', 'deskripsi' => 'Alpha', 'keterangan' => null],
            ['kode' => 'B2', 'deskripsi' => 'Beta', 'keterangan' => null],
        ]);

        $resp = $this->getJson('/api/general/dropdown?table_name=m_tindakan_segera&search=Alpha');
        $resp->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonCount(1, 'data');
    }
}

