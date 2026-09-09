<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $tables = [
            'categories',
            'products',
            'tables',
            'transactions',
            'raw_materials',
            'cashier_shifts',
            'finance_entries',
            'stock_logs',
            'activity_logs',
        ];

        foreach ($tables as $tableName) {
            if (Schema::hasTable($tableName) && !Schema::hasColumn($tableName, 'branch_id')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->unsignedBigInteger('branch_id')->default(1)->after('id');
                    $table->index('branch_id');
                });
                // Ensure all existing rows have branch_id = 1
                DB::table($tableName)->whereNull('branch_id')->update(['branch_id' => 1]);
            }
        }
    }

    public function down(): void
    {
        $tables = [
            'categories',
            'products',
            'tables',
            'transactions',
            'raw_materials',
            'cashier_shifts',
            'finance_entries',
            'stock_logs',
            'activity_logs',
        ];

        foreach ($tables as $tableName) {
            if (Schema::hasTable($tableName) && Schema::hasColumn($tableName, 'branch_id')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->dropColumn('branch_id');
                });
            }
        }
    }
};
