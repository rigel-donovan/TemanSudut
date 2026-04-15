<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $fillable = ['category_id', 'name', 'slug', 'description', 'sku', 'price', 'hpp', 'stock', 'image', 'is_active'];

    protected $casts = [
        'price' => 'decimal:2',
        'hpp' => 'decimal:2',
    ];

    protected $appends = ['profit'];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function ingredients()
    {
        return $this->hasMany(ProductIngredient::class);
    }

    /**
     * Calculate HPP from ingredients and save to the database.
     */
    public function calculateHpp(): float
    {
        $this->load('ingredients.rawMaterial');
        $hpp = 0;

        foreach ($this->ingredients as $ingredient) {
            if ($ingredient->rawMaterial) {
                $hpp += $ingredient->quantity_used * (float) $ingredient->rawMaterial->price_per_small_unit;
            }
        }

        $this->updateQuietly(['hpp' => round($hpp, 2)]);
        return $hpp;
    }

    /**
     * Calculate max possible stock from ingredients and save to database.
     */
    public function syncStock(): int
    {
        $this->load('ingredients.rawMaterial');
        $maxServings = null;

        if ($this->ingredients->isEmpty()) {
            return (int) $this->stock; 
        }

        foreach ($this->ingredients as $ingredient) {
            if (!$ingredient->rawMaterial) continue;

            $available = (float) $ingredient->rawMaterial->stock;
            $needed = (float) $ingredient->quantity_used;

            if ($needed > 0) {
                $servings = floor($available / $needed);
                if ($maxServings === null || $servings < $maxServings) {
                    $maxServings = $servings;
                }
            }
        }

        $newStock = $maxServings === null ? 0 : (int) $maxServings;
        
        if ($this->stock != $newStock) {
            // updateQuietly prevents firing 'saved' again if we had observers
            $this->updateQuietly(['stock' => $newStock]);
        }

        return $newStock;
    }

    /**
     * Profit = selling price - HPP
     */
    public function getProfitAttribute(): float
    {
        return (float) $this->price - (float) $this->hpp;
    }
}
