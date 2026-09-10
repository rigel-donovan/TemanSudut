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

    /**
     * Get counts of all operational records tied to this branch.
     */
    public function getDataSummary(): array
    {
        return [
            'products' => \Illuminate\Support\Facades\DB::table('products')->where('branch_id', $this->id)->count(),
            'transactions' => \Illuminate\Support\Facades\DB::table('transactions')->where('branch_id', $this->id)->count(),
            'categories' => \Illuminate\Support\Facades\DB::table('categories')->where('branch_id', $this->id)->count(),
            'raw_materials' => \Illuminate\Support\Facades\DB::table('raw_materials')->where('branch_id', $this->id)->count(),
            'tables' => \Illuminate\Support\Facades\DB::table('tables')->where('branch_id', $this->id)->count(),
            'shifts' => \Illuminate\Support\Facades\DB::table('cashier_shifts')->where('branch_id', $this->id)->count(),
            'finance_entries' => \Illuminate\Support\Facades\DB::table('finance_entries')->where('branch_id', $this->id)->count(),
        ];
    }

    /**
     * Check if this branch contains any operational data.
     */
    public function hasData(): bool
    {
        return array_sum($this->getDataSummary()) > 0;
    }

    /**
     * Safely delete this branch and all its associated data after verifying password.
     */
    public function safeDeleteWithPassword(string $password, User $actingUser): void
    {
        if (!\Illuminate\Support\Facades\Hash::check($password, $actingUser->password)) {
            throw \Illuminate\Validation\ValidationException::withMessages([
                'password' => ['Password akun yang Anda masukkan salah. Konfirmasi penghapusan gagal.'],
            ]);
        }

        if (static::count() <= 1) {
            throw new \Exception('Tidak dapat menghapus cabang. Minimal harus tersisa 1 cabang aktif di sistem.');
        }

        \Illuminate\Support\Facades\DB::transaction(function () {
            $branchId = $this->id;

            // 1. Transaction items & Transactions
            $transactionIds = \Illuminate\Support\Facades\DB::table('transactions')->where('branch_id', $branchId)->pluck('id');
            if ($transactionIds->isNotEmpty()) {
                \Illuminate\Support\Facades\DB::table('transaction_items')->whereIn('transaction_id', $transactionIds)->delete();
                \Illuminate\Support\Facades\DB::table('transactions')->where('branch_id', $branchId)->delete();
            }

            // 2. Product ingredients & Products
            $productIds = \Illuminate\Support\Facades\DB::table('products')->where('branch_id', $branchId)->pluck('id');
            if ($productIds->isNotEmpty()) {
                \Illuminate\Support\Facades\DB::table('product_ingredients')->whereIn('product_id', $productIds)->delete();
                \Illuminate\Support\Facades\DB::table('products')->where('branch_id', $branchId)->delete();
            }

            // 3. Other tenant tables
            \Illuminate\Support\Facades\DB::table('categories')->where('branch_id', $branchId)->delete();
            \Illuminate\Support\Facades\DB::table('raw_materials')->where('branch_id', $branchId)->delete();
            \Illuminate\Support\Facades\DB::table('tables')->where('branch_id', $branchId)->delete();
            \Illuminate\Support\Facades\DB::table('cashier_shifts')->where('branch_id', $branchId)->delete();
            \Illuminate\Support\Facades\DB::table('finance_entries')->where('branch_id', $branchId)->delete();
            \Illuminate\Support\Facades\DB::table('stock_logs')->where('branch_id', $branchId)->delete();
            \Illuminate\Support\Facades\DB::table('activity_logs')->where('branch_id', $branchId)->delete();

            // 4. Detach from users
            \Illuminate\Support\Facades\DB::table('branch_user')->where('branch_id', $branchId)->delete();

            // 5. Delete branch
            $this->delete();
        });
    }
}
