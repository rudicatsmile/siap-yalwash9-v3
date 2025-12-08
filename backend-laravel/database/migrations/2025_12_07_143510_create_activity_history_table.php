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
        Schema::create('activity_history', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('document_id')->nullable();
            $table->string('action', 100); // login, logout, create_document, update_document, view_document, status_change, meeting_decision
            $table->text('description')->nullable();
            $table->json('metadata')->nullable(); // Store additional context as JSON
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamps();
            
            // Foreign keys
            $table->foreign('user_id')->references('id_user')->on('users')->onDelete('cascade');
            $table->foreign('document_id')->references('id_sm')->on('tbl_sm')->onDelete('cascade');
            
            // Indexes for performance
            $table->index('user_id');
            $table->index('document_id');
            $table->index('action');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('activity_history');
    }
};
