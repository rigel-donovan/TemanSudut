<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Category;
use App\Models\Product;
use App\Models\Table;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Admin user
        User::factory()->create([
            'name' => 'Admin',
            'email' => 'admin@admin.com',
            'password' => Hash::make('password'),
        ]);

        // Tables
        Table::create(['name' => 'Meja 1', 'status' => 'available']);
        Table::create(['name' => 'Meja 2', 'status' => 'available']);
        Table::create(['name' => 'Meja 3', 'status' => 'available']);
        Table::create(['name' => 'Outdoor 1', 'status' => 'available']);
        Table::create(['name' => 'Outdoor 2', 'status' => 'available']);

        // Categories
        $catCoffee = Category::create(['name' => 'Kopi', 'slug' => 'kopi']);
        $catNonCoffee = Category::create(['name' => 'Non-Kopi', 'slug' => 'non-kopi']);
        $catFood = Category::create(['name' => 'Makanan', 'slug' => 'makanan']);

        // Products
        Product::create([
            'category_id' => $catCoffee->id,
            'name' => 'Kopi Susu Gula Aren',
            'slug' => 'kopi-susu-gula-aren',
            'sku' => 'KOP-001',
            'price' => 25000,
            'stock' => 50,
        ]);
        Product::create([
            'category_id' => $catCoffee->id,
            'name' => 'Americano',
            'slug' => 'americano',
            'sku' => 'KOP-002',
            'price' => 20000,
            'stock' => 50,
        ]);
        Product::create([
            'category_id' => $catNonCoffee->id,
            'name' => 'Lychee Tea',
            'slug' => 'lychee-tea',
            'sku' => 'NON-001',
            'price' => 22000,
            'stock' => 50,
        ]);
        Product::create([
            'category_id' => $catFood->id,
            'name' => 'Nasi Goreng Spesial',
            'slug' => 'nasi-goreng-spesial',
            'sku' => 'MAK-001',
            'price' => 35000,
            'stock' => 20,
        ]);
        Product::create([
            'category_id' => $catFood->id,
            'name' => 'French Fries',
            'slug' => 'french-fries',
            'sku' => 'MAK-002',
            'price' => 20000,
            'stock' => 30,
        ]);
    }
}
