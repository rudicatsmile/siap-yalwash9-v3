<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (Schema::hasTable('m_instansi')) {
            return;
        }
        Schema::create('m_instansi', function (Blueprint $table) {
            $table->id();
            $table->string('kode', 100)->unique();
            $table->string('deskripsi', 255);
            $table->string('keterangan', 255)->nullable();
            $table->string('telp', 20)->nullable();
            $table->unsignedBigInteger('id_user')->nullable();
            $table->string('kode_surat', 100)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('m_instansi');
    }
};
