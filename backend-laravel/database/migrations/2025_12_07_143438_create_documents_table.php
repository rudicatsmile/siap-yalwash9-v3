<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tbl_sm', function (Blueprint $table) {
            $table->id('id_sm');
            $table->string('no_surat', 50);
            $table->date('tgl_ns');
            $table->string('no_asal', 100);
            $table->date('tgl_no_asal')->nullable();
            $table->date('tgl_no_asal2')->nullable();
            $table->date('tgl_surat');
            $table->string('pengirim', 255);
            $table->string('penerima', 255);
            $table->text('perihal');
            $table->string('token_lampiran', 100)->nullable();
            $table->string('token_lampiran_tu', 100)->nullable();
            $table->text('bagian')->nullable();
            $table->text('disposisi')->nullable();
            $table->unsignedBigInteger('id_user');
            $table->string('kode_user', 100);
            $table->string('kode_user_approved', 100)->nullable();
            $table->unsignedBigInteger('id_user_approved')->default(0);
            $table->string('id_instansi', 50);
            $table->string('id_instansi_approved', 50)->nullable();
            $table->string('id_user_disposisi_leader', 50)->nullable();
            $table->date('tgl_sm')->nullable();
            $table->string('lampiran', 255)->nullable();
            $table->enum('status', ['Dokumen', 'Rapat', 'Selesai'])->default('Dokumen');
            $table->enum('sifat', ['Segera', 'Biasa', 'Rahasia'])->default('Biasa');
            $table->boolean('dibaca')->default(0);
            $table->boolean('dibaca_pimpinan')->default(0);
            $table->string('kode_user_pimpinan', 100)->nullable();
            $table->timestamp('tgl_ajuan')->nullable();
            $table->timestamp('tgl_ajuan_delegate')->nullable();
            $table->string('segera', 50)->nullable();
            $table->string('biasa', 50)->nullable();
            $table->text('catatan')->nullable();
            $table->timestamp('tgl_disposisi')->nullable();
            $table->timestamp('tgl_approved')->nullable();
            $table->text('catatan_koreksi')->nullable();
            $table->boolean('is_notes_pimpinan')->default(0);
            $table->boolean('status_tu')->default(0);
            $table->boolean('status_instansi')->default(0);
            $table->timestamp('tgl_delegasi_rapat')->nullable();
            $table->string('tgl_agenda_rapat', 100)->nullable();
            $table->timestamp('tgl_hasil_rapat')->nullable();
            $table->boolean('delegasi_pimpinan')->default(0);
            $table->text('disposisi_rapat')->nullable();
            $table->text('delegasi_tu')->nullable();
            $table->string('ruang_rapat', 255)->nullable();
            $table->string('penanda_tangan_rapat', 255)->nullable();
            $table->text('tembusan_rapat')->nullable();
            $table->string('jam_rapat', 100)->nullable();
            $table->text('bahasan_rapat')->nullable();
            $table->text('pimpinan_rapat')->nullable();
            $table->text('peserta_rapat')->nullable();
            $table->string('ditujukan', 255)->nullable();
            $table->text('instruksi_kerja')->nullable();
            $table->text('disposisi_memo')->nullable();
            $table->string('kategori_berkas', 100)->nullable();
            $table->string('kategori_undangan', 100)->nullable();
            $table->string('kategori_laporan', 100)->nullable();
            $table->string('id_status_rapat', 50)->default('1');
            $table->string('kode_user_ditujukan_memo', 100)->nullable();
            $table->string('kategori_surat', 100);
            $table->string('kode_berkas', 100);
            $table->string('klasifikasi_surat', 100);
            $table->text('disposisi_ktu_leader')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Foreign key
            $table->foreign('id_user')->references('id_user')->on('users')->onDelete('cascade');

            // Indexes for performance
            $table->index('id_user');
            $table->index('id_instansi');
            $table->index('status');
            $table->index('tgl_surat');
            $table->index('no_surat');
            $table->index(['id_instansi', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_sm');
    }
};
