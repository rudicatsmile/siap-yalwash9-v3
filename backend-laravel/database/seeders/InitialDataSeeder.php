<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Document;
use Illuminate\Support\Facades\Hash;

class InitialDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create additional test users first
        User::create([
            'username' => 'admin',
            'password' => Hash::make('admin123'),
            'nama_lengkap' => 'Administrator',
            'jabatan' => 'System Administrator',
            'role' => 'admin',
            'instansi' => '10',
            'email' => 'admin@siap.local',
            'telp' => '08123456789',
            'level' => 'admin',
            'level_admin' => 'A1',
            'level_manajemen' => '0',
            'kode_user' => 'ADMIN-001',
        ]);

        User::create([
            'username' => 'pimpinan',
            'password' => Hash::make('pimpinan123'),
            'nama_lengkap' => 'Pimpinan Utama',
            'jabatan' => 'Kepala Bagian',
            'role' => 'pimpinan',
            'instansi' => '10',
            'email' => 'pimpinan@siap.local',
            'telp' => '08987654321',
            'level' => 'pimpinan',
            'level_pimpinan' => 'P1',
            'level_manajemen' => '0',
            'kode_user' => 'PMP-001',
        ]);

        $this->command->info('Test users created successfully');

        // Load user data from JSON
        $userJsonPath = base_path('../json-files/user.json');
        if (file_exists($userJsonPath)) {
            $userData = json_decode(file_get_contents($userJsonPath), true);
            
            if (isset($userData['data'])) {
                $user = $userData['data'];
                
                User::create([
                    'username' => $user['username'],
                    'password' => Hash::make('password123'), // Default password, not the hash from JSON
                    'nama_lengkap' => $user['nama_lengkap'],
                    'jabatan' => $user['jabatan'],
                    'role' => $user['role'],
                    'instansi' => $user['instansi'],
                    'email' => $user['email'],
                    'telp' => $user['telp'],
                    'alamat' => $user['alamat'],
                    'pengalaman' => $user['pengalaman'],
                    'level' => $user['level'],
                    'level_pimpinan' => $user['level_pimpinan'],
                    'level_tu' => $user['level_tu'],
                    'level_admin' => $user['level_admin'],
                    'level_manajemen' => $user['level_manajemen'],
                    'kode_user' => $user['kode_user'],
                    'status' => $user['status'],
                    'terakhir_login' => $user['terakhir_login'] ? \Carbon\Carbon::createFromFormat('d-m-Y H:i:s', $user['terakhir_login']) : null,
                    'fcm_token' => $user['fcm_token'],
                ]);
                
                $this->command->info('User from JSON seeded successfully');
            }
        }

        // Load document data from JSON
        $docJsonPath = base_path('../json-files/tbl_sm.json');
        if (file_exists($docJsonPath)) {
            $docData = json_decode(file_get_contents($docJsonPath), true);
            
            if (isset($docData['data'])) {
                $doc = $docData['data'];
                
                // Get first user to associate with document if the original user doesn't exist
                $userId = User::where('kode_user', $doc['kode_user'])->first()?->id_user ?? User::first()->id_user;
                
                Document::create([
                    'no_surat' => $doc['no_surat'],
                    'tgl_ns' => \Carbon\Carbon::createFromFormat('d-m-Y', $doc['tgl_ns'])->toDateString(),
                    'no_asal' => $doc['no_asal'],
                    'tgl_no_asal' => $doc['tgl_no_asal'],
                    'tgl_no_asal2' => $doc['tgl_no_asal2'],
                    'tgl_surat' => $doc['tgl_surat'],
                    'pengirim' => $doc['pengirim'],
                    'penerima' => $doc['penerima'],
                    'perihal' => $doc['perihal'],
                    'token_lampiran' => $doc['token_lampiran'],
                    'token_lampiran_tu' => $doc['token_lampiran_tu'],
                    'bagian' => $doc['bagian'],
                    'disposisi' => $doc['disposisi'],
                    'id_user' => $userId,  // Use the found or first user ID
                    'kode_user' => $doc['kode_user'],
                    'kode_user_approved' => $doc['kode_user_approved'],
                    'id_user_approved' => $doc['id_user_approved'],
                    'id_instansi' => $doc['id_instansi'],
                    'id_instansi_approved' => $doc['id_instansi_approved'],
                    'id_user_disposisi_leader' => $doc['id_user_disposisi_leader'],
                    'tgl_sm' => $doc['tgl_sm'],
                    'lampiran' => $doc['lampiran'],
                    'status' => $doc['status'],
                    'sifat' => $doc['sifat'],
                    'dibaca' => $doc['dibaca'],
                    'dibaca_pimpinan' => $doc['dibaca_pimpinan'],
                    'kode_user_pimpinan' => $doc['kode_user_pimpinan'],
                    'segera' => $doc['segera'],
                    'biasa' => $doc['biasa'],
                    'catatan' => $doc['catatan'],
                    'catatan_koreksi' => $doc['catatan_koreksi'],
                    'is_notes_pimpinan' => $doc['is_notes_pimpinan'],
                    'status_tu' => $doc['status_tu'],
                    'status_instansi' => $doc['status_instansi'],
                    'ruang_rapat' => $doc['ruang_rapat'],
                    'penanda_tangan_rapat' => $doc['penanda_tangan_rapat'],
                    'tembusan_rapat' => $doc['tembusan_rapat'],
                    'jam_rapat' => $doc['jam_rapat'],
                    'bahasan_rapat' => $doc['bahasan_rapat'],
                    'pimpinan_rapat' => $doc['pimpinan_rapat'],
                    'peserta_rapat' => $doc['peserta_rapat'],
                    'ditujukan' => $doc['ditujukan'],
                    'instruksi_kerja' => $doc['instruksi_kerja'],
                    'disposisi_memo' => $doc['disposisi_memo'],
                    'kategori_berkas' => $doc['kategori_berkas'],
                    'kategori_undangan' => $doc['kategori_undangan'],
                    'kategori_laporan' => $doc['kategori_laporan'],
                    'id_status_rapat' => $doc['id_status_rapat'],
                    'kode_user_ditujukan_memo' => $doc['kode_user_ditujukan_memo'],
                    'kategori_surat' => $doc['kategori_surat'],
                    'klasifikasi_surat' => $doc['klasifikasi_surat'],
                    'disposisi_ktu_leader' => $doc['disposisi_ktu_leader'],
                ]);
                
                $this->command->info('Document seeded successfully');
            }
        }
    }
}
