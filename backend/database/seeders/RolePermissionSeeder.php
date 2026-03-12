<?php

namespace Database\Seeders;

use App\Models\RolePermission;
use Illuminate\Database\Seeder;

class RolePermissionSeeder extends Seeder
{
    /**
     * Feature list with their default access per role.
     * [ 'feature_key' => ['label' => 'Label', 'owner' => bool, 'cashier' => bool] ]
     */
    public static array $features = [
        'print_receipt'     => ['label' => 'Cetak Struk',               'owner' => true,  'cashier' => true],
        'view_history'      => ['label' => 'Lihat Riwayat Transaksi',   'owner' => true,  'cashier' => true],
        'manage_employees'  => ['label' => 'Kelola Karyawan',           'owner' => true,  'cashier' => false],
        'manage_products'   => ['label' => 'Kelola Produk',             'owner' => true,  'cashier' => false],
        'open_shift'        => ['label' => 'Buka / Tutup Kasir',        'owner' => true,  'cashier' => true],
        'access_management' => ['label' => 'Akses Menu Management',     'owner' => true,  'cashier' => false],
        'manage_stock'      => ['label' => 'Manajemen Stok',            'owner' => true,  'cashier' => false],
        'manage_printer'    => ['label' => 'Manajemen Printer',         'owner' => true,  'cashier' => true],
        'manage_raw_materials' => ['label' => 'Bahan Baku',             'owner' => true,  'cashier' => false],
    ];

    public function run(): void
    {
        foreach (self::$features as $feature => $config) {
            foreach (['owner', 'cashier'] as $role) {
                RolePermission::updateOrCreate(
                    ['feature' => $feature, 'role' => $role],
                    ['enabled' => $config[$role]]
                );
            }
        }
    }
}
