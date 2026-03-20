<?php

namespace App\Models;

use App\Models\Transaction;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CashierShift extends Model
{
    protected $fillable = [
        'user_id',
        'starting_cash',
        'ending_cash',
        'status',
        'opened_at',
        'closed_at',
    ];

    protected $casts = [
        'opened_at' => 'datetime',
        'closed_at' => 'datetime',
        'starting_cash' => 'decimal:2',
        'ending_cash' => 'decimal:2',
    ];

    protected $appends = ['current_cash'];

    public function getCurrentCashAttribute()
    {
        $cashSales = Transaction::where('user_id', $this->user_id)
            ->where('created_at', '>=', $this->opened_at)
            ->where(function($q) {
                if ($this->closed_at) {
                    $q->where('created_at', '<=', $this->closed_at);
                }
            })
            ->whereIn('payment_method', ['cash', 'tunai'])
            ->sum('total');

        return (float) $this->starting_cash + (float) $cashSales;
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
