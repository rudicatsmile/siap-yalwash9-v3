<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('tbl_sm_child', function (Blueprint $table) {
            $table->id('id_sm_child');
            $table->unsignedBigInteger('id_sm');
            $table->string('no_asal', 255);
            $table->date('tgl_agenda_rapat');
            $table->time('jam_rapat');
            $table->text('bahasan_rapat');
            $table->string('pimpinan_rapat', 255);
            $table->text('peserta_rapat');
            $table->unsignedInteger('id_status_rapat');
            $table->timestamps();

            $table->index('id_sm');
            $table->index('id_status_rapat');
            $table->foreign('id_sm')->references('id_sm')->on('tbl_sm')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tbl_sm_child');
    }
};

