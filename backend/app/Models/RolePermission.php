<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RolePermission extends Model
{
    protected $fillable = ['feature', 'role', 'enabled'];

    protected $casts = [
        'enabled' => 'boolean',
    ];

    /**
     * Get all permissions as a nested array: ['feature' => ['owner' => bool, 'cashier' => bool]]
     */
    public static function allAsMatrix(): array
    {
        $all = static::all();
        $matrix = [];
        foreach ($all as $perm) {
            $matrix[$perm->feature][$perm->role] = $perm->enabled;
        }
        return $matrix;
    }

    /**
     * Check if a specific role has a feature enabled.
     */
    public static function isAllowed(string $feature, string $role): bool
    {
        $perm = static::where('feature', $feature)->where('role', $role)->first();
        return $perm ? (bool) $perm->enabled : false;
    }
}
