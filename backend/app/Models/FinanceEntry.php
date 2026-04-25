<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FinanceEntry extends Model
{
    protected $fillable = [
        'type',
        'category',
        'description',
        'amount',
        'date',
        'notes',
        'user_id',
    ];

    protected $casts = [
        'date'   => 'date',
        'amount' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Predefined categories
    public static function incomeCategories(): array
    {
        return [
            'Penjualan'       => 'Penjualan',
            'Bonus'           => 'Bonus',
            'Investasi'       => 'Investasi',
            'Lain-lain'       => 'Lain-lain',
        ];
    }

    public static function expenseCategories(): array
    {
        return [
            'Belanja Bahan'   => 'Belanja Bahan',
            'Gaji Karyawan'   => 'Gaji Karyawan',
            'Listrik & Air'   => 'Listrik & Air',
            'Sewa Tempat'     => 'Sewa Tempat',
            'Peralatan'       => 'Peralatan',
            'Operasional'     => 'Operasional',
            'Marketing'       => 'Marketing',
            'Lain-lain'       => 'Lain-lain',
        ];
    }
}
