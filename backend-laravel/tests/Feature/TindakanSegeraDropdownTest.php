<?php

namespace Tests\Feature;

use App\Models\TindakanSegera;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TindakanSegeraDropdownTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_endpoint_returns_success_and_expected_structure(): void
    {
        TindakanSegera::create(['kode' => 'TS-01', 'deskripsi' => 'Segera tangani', 'keterangan' => 'Prioritas tinggi']);

        $resp = $this->getJson('/api/tindakan-segera/dropdown');

        $resp->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    ['value', 'label', 'keterangan']
                ],
                'message',
            ])
            ->assertJsonFragment([
                'success' => true,
                'message' => 'Data tindakan segera berhasil diambil',
            ]);
    }

    public function test_search_filters_results(): void
    {
        TindakanSegera::create(['kode' => 'A1', 'deskripsi' => 'Alpha', 'keterangan' => null]);
        TindakanSegera::create(['kode' => 'B2', 'deskripsi' => 'Beta', 'keterangan' => null]);

        $resp = $this->getJson('/api/tindakan-segera/dropdown?search=Alpha');

        $resp->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonCount(1, 'data');
    }

    public function test_empty_data_returns_empty_array(): void
    {
        $resp = $this->getJson('/api/tindakan-segera/dropdown');
        $resp->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonCount(0, 'data');
    }
}

