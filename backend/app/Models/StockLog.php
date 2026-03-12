<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StockLog extends Model
{
    protected $fillable = [
        'product_id', 'user_id', 'type', 'quantity',
        'stock_before', 'stock_after', 'reason', 'notes',
    ];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Adjust stock for a product and record the log.
     */
    public static function adjustStock(
        int $productId,
        int $quantity,
        string $type = 'adjustment',
        ?string $reason = null,
        ?string $notes = null,
        ?int $userId = null
    ): static {
        $product = Product::findOrFail($productId);
        $stockBefore = $product->stock;
        $stockAfter = max(0, $stockBefore + $quantity);

        $product->update(['stock' => $stockAfter]);

        return static::create([
            'product_id'   => $productId,
            'user_id'      => $userId ?? auth()->id(),
            'type'         => $type,
            'quantity'     => $quantity,
            'stock_before' => $stockBefore,
            'stock_after'  => $stockAfter,
            'reason'       => $reason,
            'notes'        => $notes,
        ]);
    }
}
