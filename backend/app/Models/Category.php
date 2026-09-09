<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    protected $fillable = ['branch_id', 'name', 'slug', 'description', 'image', 'is_active'];

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }

    public function products()
    {
        return $this->hasMany(Product::class);
    }
}