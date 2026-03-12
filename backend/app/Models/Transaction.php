<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = ['user_id', 'table_id', 'order_type', 'customer_name', 'subtotal', 'tax', 'total', 'payment_method', 'payment_status', 'kitchen_status', 'notes', 'completion_photo'];

    public function items()
    {
        return $this->hasMany(TransactionItem::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function table()
    {
        return $this->belongsTo(Table::class);
    }
}
