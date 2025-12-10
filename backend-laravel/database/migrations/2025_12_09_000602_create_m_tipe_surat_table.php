<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (Schema::hasTable('m_tipe_surat')) {
            return;
        }
        Schema::create('m_tipe_surat', function (Blueprint $table) {
            $table->id('id_tipe_surat');
            $table->string('klasifikasi_surat_keluar', 255);
            $table->string('kode', 100)->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('m_tipe_surat');
    }
};
