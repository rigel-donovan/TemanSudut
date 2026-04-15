<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductIngredient extends Model
{
    protected $fillable = ['product_id', 'raw_material_id', 'quantity_used'];

    protected $casts = [
        'quantity_used' => 'decimal:2',
    ];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function rawMaterial()
    {
        return $this->belongsTo(RawMaterial::class);
    }

    protected static function booted(): void
    {
        static::saved(function (ProductIngredient $ingredient) {
            if ($ingredient->product) {
                $ingredient->product->syncStock();
                $ingredient->product->calculateHpp();
            }
        });

        static::deleted(function (ProductIngredient $ingredient) {
            if ($ingredient->product) {
                $ingredient->product->syncStock();
                $ingredient->product->calculateHpp();
            }
        });
    }
}
