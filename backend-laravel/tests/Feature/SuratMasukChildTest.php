<?php

namespace Tests\Feature;

use App\Models\Document;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SuratMasukChildTest extends TestCase
{
    use RefreshDatabase;

    protected function createUser(): User
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

    protected function createDocument(int $userId, string $kodeUser): Document
    {
        return Document::create([
            'no_surat' => 'SM-001',
            'tgl_ns' => '2026-04-02',
            'no_asal' => 'ASAL-001',
            'tgl_surat' => '2026-04-02',
            'pengirim' => 'Pengirim',
            'penerima' => 'Penerima',
            'perihal' => 'Perihal',
            'id_user' => $userId,
            'kode_user' => $kodeUser,
            'id_instansi' => '10',
            'status' => 'Dokumen',
            'sifat' => 'Biasa',
            'dibaca' => 0,
            'dibaca_pimpinan' => 0,
            'kategori_surat' => 'MEMO',
            'kode_berkas' => 'KODE',
            'klasifikasi_surat' => 'KLASIF',
        ]);
    }

    public function test_requires_authentication(): void
    {
        $resp = $this->postJson('/api/surat-masuk/child', []);
        $resp->assertStatus(401);
    }

    public function test_insert_success_when_id_status_rapat_not_1(): void
    {
        $user = $this->createUser();
        Sanctum::actingAs($user);
        $doc = $this->createDocument($user->id_user, $user->kode_user);

        $payload = [
            'id_sm' => $doc->id_sm,
            'no_asal' => 'ASAL-001',
            'tgl_agenda_rapat' => '2026-04-02',
            'jam_rapat' => '10:30:00',
            'bahasan_rapat' => 'Pembahasan A',
            'pimpinan_rapat' => 'Pimpinan A',
            'peserta_rapat' => 'Peserta 1<br>Peserta 2',
            'id_status_rapat' => 3,
        ];

        $resp = $this->postJson('/api/surat-masuk/child', $payload);
        $resp->assertStatus(201)->assertJson(['success' => true]);

        $this->assertDatabaseHas('tbl_sm_child', [
            'id_sm' => $doc->id_sm,
            'id_status_rapat' => 3,
            'no_asal' => 'ASAL-001',
        ]);
    }

    public function test_insert_rejected_when_id_status_rapat_is_1(): void
    {
        $user = $this->createUser();
        Sanctum::actingAs($user);
        $doc = $this->createDocument($user->id_user, $user->kode_user);

        $payload = [
            'id_sm' => $doc->id_sm,
            'no_asal' => 'ASAL-001',
            'tgl_agenda_rapat' => '2026-04-02',
            'jam_rapat' => '10:30:00',
            'bahasan_rapat' => 'Pembahasan A',
            'pimpinan_rapat' => 'Pimpinan A',
            'peserta_rapat' => 'Peserta 1',
            'id_status_rapat' => 1,
        ];

        $resp = $this->postJson('/api/surat-masuk/child', $payload);
        $resp->assertStatus(400)->assertJson(['success' => false]);

        $this->assertDatabaseMissing('tbl_sm_child', [
            'id_sm' => $doc->id_sm,
            'id_status_rapat' => 1,
        ]);
    }

    public function test_validation_date_and_time_format(): void
    {
        $user = $this->createUser();
        Sanctum::actingAs($user);
        $doc = $this->createDocument($user->id_user, $user->kode_user);

        $payload = [
            'id_sm' => $doc->id_sm,
            'no_asal' => 'ASAL-001',
            'tgl_agenda_rapat' => '02-04-2026',
            'jam_rapat' => '10:30',
            'bahasan_rapat' => 'Pembahasan A',
            'pimpinan_rapat' => 'Pimpinan A',
            'peserta_rapat' => 'Peserta 1',
            'id_status_rapat' => 3,
        ];

        $resp = $this->postJson('/api/surat-masuk/child', $payload);
        $resp->assertStatus(400)->assertJson(['success' => false]);
        $resp->assertJsonStructure(['success', 'message', 'errors']);
    }

    public function test_required_fields_validated(): void
    {
        $user = $this->createUser();
        Sanctum::actingAs($user);
        $doc = $this->createDocument($user->id_user, $user->kode_user);

        $payload = [
            'id_sm' => $doc->id_sm,
            'no_asal' => 'ASAL-001',
            'tgl_agenda_rapat' => '2026-04-02',
            'jam_rapat' => '10:30:00',
            'bahasan_rapat' => 'Pembahasan A',
            'pimpinan_rapat' => 'Pimpinan A',
            'id_status_rapat' => 3,
        ];

        $resp = $this->postJson('/api/surat-masuk/child', $payload);
        $resp->assertStatus(400)->assertJson(['success' => false]);
        $resp->assertJsonStructure(['errors' => ['peserta_rapat']]);
    }
}

