<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Branch extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'address',
        'phone',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'branch_user');
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function categories(): HasMany
    {
        return $this->hasMany(Category::class);
    }

    public function tables(): HasMany
    {
        return $this->hasMany(Table::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    public function rawMaterials(): HasMany
    {
        return $this->hasMany(RawMaterial::class);
    }

    public function financeEntries(): HasMany
    {
        return $this->hasMany(FinanceEntry::class);
    }

    public function shifts(): HasMany
    {
        return $this->hasMany(CashierShift::class);
    }

    public static function currentId(?\Illuminate\Http\Request $request = null): int
    {
        $request = $request ?? request();
        $branchId = $request->header('X-Branch-Id') ?? $request->query('branch_id');
        if ($branchId) {
            return (int) $branchId;
        }
        if (auth()->check()) {
            $user = auth()->user();
            if (!$user->isOwner()) {
                $userBranch = $user->branches()->first();
                if ($userBranch) {
                    return (int) $userBranch->id;
                }
            }
        }
        return 1;
    }

    public static function current(?\Illuminate\Http\Request $request = null): ?self
    {
        return static::find(static::currentId($request));
    }
}
