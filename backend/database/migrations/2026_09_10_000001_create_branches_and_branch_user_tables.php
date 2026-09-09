<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('branches', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('address')->nullable();
            $table->string('phone')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('branch_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('branch_id')->constrained('branches')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['branch_id', 'user_id']);
        });

        // Seed default branch "Cabang Ring Road"
        $now = now();
        DB::table('branches')->insert([
            'id' => 1,
            'name' => 'Cabang Ring Road',
            'address' => 'Jl. Ring Road',
            'phone' => null,
            'is_active' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        // Seed second branch "Cabang BDS" for testing / multi-branch readiness
        DB::table('branches')->insert([
            'id' => 2,
            'name' => 'Cabang BDS',
            'address' => 'Jl. BDS',
            'phone' => null,
            'is_active' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        // Associate all existing users with branch 1
        $users = DB::table('users')->pluck('id');
        foreach ($users as $userId) {
            DB::table('branch_user')->insertOrIgnore([
                'branch_id' => 1,
                'user_id' => $userId,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('branch_user');
        Schema::dropIfExists('branches');
    }
};
