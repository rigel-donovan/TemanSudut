<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RawMaterial extends Model
{
    protected $fillable = ['name', 'stock', 'unit', 'min_stock', 'is_active', 'image'];

    protected $casts = [
        'stock' => 'decimal:2',
        'min_stock' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    /**
     * Adjust stock for a raw material and record the log.
     */
    public static function adjustStock(
        int $rawMaterialId,
        float $quantity,
        string $type = 'adjustment',
        ?string $reason = null,
        ?string $notes = null,
        ?int $userId = null
    ): static {
        $material = static::findOrFail($rawMaterialId);
        $stockBefore = (float) $material->stock;
        $stockAfter = max(0, $stockBefore + $quantity);

        $material->update(['stock' => $stockAfter]);

        StockLog::create([
            'raw_material_id' => $rawMaterialId,
            'user_id'         => $userId ?? auth()->id(),
            'type'            => $type,
            'quantity'        => $quantity,
            'stock_before'    => $stockBefore,
            'stock_after'     => $stockAfter,
            'reason'          => $reason,
            'notes'           => $notes,
        ]);

        return $material;
    }
}
