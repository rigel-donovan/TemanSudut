<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Table extends Model
{
    /** @use HasFactory<\Database\Factories\TableFactory> */
    use HasFactory;

    protected $fillable = ['branch_id', 'name', 'status'];

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}
