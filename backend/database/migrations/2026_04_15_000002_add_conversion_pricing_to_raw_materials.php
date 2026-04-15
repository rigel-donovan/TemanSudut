<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('raw_materials', function (Blueprint $table) {
            $table->string('brand')->nullable()->after('name');
            $table->string('unit_large')->nullable()->after('unit')->comment('kg, liter, item');
            $table->string('unit_small')->nullable()->after('unit_large')->comment('gr, ml, pcs');
            $table->decimal('conversion_value', 10, 2)->default(1)->after('unit_small')->comment('1 large = X small');
            $table->decimal('price_per_large_unit', 15, 2)->default(0)->after('conversion_value');
            $table->decimal('price_per_small_unit', 15, 4)->default(0)->after('price_per_large_unit');
        });
    }

    public function down(): void
    {
        Schema::table('raw_materials', function (Blueprint $table) {
            $table->dropColumn([
                'brand', 'unit_large', 'unit_small',
                'conversion_value', 'price_per_large_unit', 'price_per_small_unit',
            ]);
        });
    }
};
