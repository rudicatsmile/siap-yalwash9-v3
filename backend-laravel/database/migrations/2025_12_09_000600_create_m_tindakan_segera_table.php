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
        if (Schema::hasTable('m_tindakan_segera')) {
            return;
        }
        Schema::create('m_tindakan_segera', function (Blueprint $table) {
            $table->id();
            $table->string('kode')->unique();
            $table->text('deskripsi');
            $table->text('keterangan')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('m_tindakan_segera');
    }
};
