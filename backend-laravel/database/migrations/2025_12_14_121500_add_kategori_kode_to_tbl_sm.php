<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('tbl_sm', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_sm', 'kategori_kode')) {
                $table->string('kategori_kode', 100)->nullable()->after('kategori_berkas');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_sm', function (Blueprint $table) {
            if (Schema::hasColumn('tbl_sm', 'kategori_kode')) {
                $table->dropColumn('kategori_kode');
            }
        });
    }
};
