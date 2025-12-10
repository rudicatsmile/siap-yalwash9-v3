<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // No-op to avoid failure if FK already dropped; FK removal handled manually previously.
    }

    public function down(): void
    {
        Schema::table('activity_history', function (Blueprint $table) {
            // Revert back to original FK to `users`
            $table->dropForeign(['user_id']);

            $table->foreign('user_id')
                ->references('id_user')
                ->on('users')
                ->onDelete('cascade');
        });
    }
};
