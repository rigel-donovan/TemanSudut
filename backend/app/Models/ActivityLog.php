<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActivityLog extends Model
{
    protected $fillable = ['branch_id', 'user_id', 'action', 'description', 'metadata', 'ip_address'];

    protected $casts = [
        'metadata' => 'array',
    ];

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public static function log(string $action, string $description, ?array $metadata = null)
    {
        $branchId = request()->header('X-Branch-Id') ?? session('filament_tenant_id') ?? 1;
        return self::create([
            'branch_id' => $branchId,
            'user_id' => auth()->id(),
            'action' => $action,
            'description' => $description,
            'metadata' => $metadata,
            'ip_address' => request()->ip(),
        ]);
    }
}
