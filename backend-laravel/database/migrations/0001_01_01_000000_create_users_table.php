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
        Schema::create('users', function (Blueprint $table) {
            $table->id('id_user');
            $table->string('username', 100)->unique();
            $table->string('password');
            $table->string('nama_lengkap', 255);
            $table->string('jabatan', 255);
            $table->enum('role', ['user', 'admin', 'pimpinan'])->default('user');
            $table->string('instansi', 50);
            $table->string('email', 255)->unique();
            $table->string('telp', 20)->nullable();
            $table->string('alamat', 255)->nullable();
            $table->text('pengalaman')->nullable();
            $table->string('level', 50);
            $table->string('level_pimpinan', 50)->nullable();
            $table->string('level_tu', 50)->nullable();
            $table->string('level_admin', 50)->nullable();
            $table->string('level_manajemen', 50)->default('0');
            $table->string('kode_user', 100)->unique();
            $table->string('status', 50)->nullable();
            $table->timestamp('tgl_daftar')->nullable();
            $table->timestamp('terakhir_login')->nullable();
            $table->text('token')->nullable();
            $table->text('fcm_token')->nullable();
            $table->integer('login_attempts')->default(0);
            $table->timestamp('last_attempt')->nullable();
            $table->timestamp('blocked_until')->nullable();
            $table->string('failed_ip', 45)->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
