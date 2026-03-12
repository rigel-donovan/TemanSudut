<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('role_permissions', function (Blueprint $table) {
            $table->id();
            $table->string('feature');
            $table->string('role'); // 'owner' or 'cashier'
            $table->boolean('enabled')->default(false);
            $table->timestamps();

            $table->unique(['feature', 'role']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('role_permissions');
    }
};
