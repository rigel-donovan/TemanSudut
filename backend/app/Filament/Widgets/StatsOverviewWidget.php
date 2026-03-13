<?php

namespace App\Filament\Widgets;

use App\Models\Product;
use App\Models\Transaction;
use App\Models\User;
use Carbon\Carbon;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverviewWidget extends BaseWidget
{
    protected static ?int $sort = 1;
    protected int | string | array $columnSpan = 'full';
    protected ?string $pollingInterval = '15s';

    protected function getStats(): array
    {
        $today = Carbon::today();
        $yesterday = Carbon::yesterday();

        // Revenue today
        $revenueToday = Transaction::whereDate('created_at', $today)
            ->where('payment_status', 'paid')
            ->sum('total');
        $revenueYesterday = Transaction::whereDate('created_at', $yesterday)
            ->where('payment_status', 'paid')
            ->sum('total');
        $revenueChange = $revenueYesterday > 0
            ? round((($revenueToday - $revenueYesterday) / $revenueYesterday) * 100, 1)
            : ($revenueToday > 0 ? 100 : 0);

        // Orders today
        $ordersToday = Transaction::whereDate('created_at', $today)->count();
        $ordersYesterday = Transaction::whereDate('created_at', $yesterday)->count();
        $ordersChange = $ordersYesterday > 0
            ? round((($ordersToday - $ordersYesterday) / $ordersYesterday) * 100, 1)
            : ($ordersToday > 0 ? 100 : 0);

        $activeProducts = Product::where('is_active', true)->count();
        $totalUsers = User::count();

        $lowStockProducts = Product::where('is_active', true)->where('stock', '<=', 5)->count();

        $lowStockRawMaterials = \App\Models\RawMaterial::where('is_active', true)
            ->whereColumn('stock', '<=', 'min_stock')
            ->count();

        $revenueSparkline = collect(range(6, 0))->map(fn($d) =>
            Transaction::whereDate('created_at', Carbon::today()->subDays($d))
                ->where('payment_status', 'paid')
                ->sum('total')
        )->toArray();

        $ordersSparkline = collect(range(6, 0))->map(fn($d) =>
            Transaction::whereDate('created_at', Carbon::today()->subDays($d))->count()
        )->toArray();

        return [
            Stat::make('Pendapatan Hari Ini', 'Rp. ' . number_format($revenueToday, 0, '.', ','))
                ->description(($revenueChange >= 0 ? '↑' : '↓') . ' ' . abs($revenueChange) . '% dibanding kemarin')
                ->descriptionIcon($revenueChange >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($revenueChange >= 0 ? 'success' : 'danger')
                ->chart($revenueSparkline),

            Stat::make('Total Order Hari Ini', $ordersToday)
                ->description(($ordersChange >= 0 ? '↑' : '↓') . ' ' . abs($ordersChange) . '% dibanding kemarin')
                ->descriptionIcon($ordersChange >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($ordersChange >= 0 ? 'success' : 'danger')
                ->chart($ordersSparkline),

            Stat::make('Total Produk', $activeProducts)
                ->description($lowStockProducts > 0 ? "$lowStockProducts stok menipis" : "Semua stok aman")
                ->descriptionIcon($lowStockProducts > 0 ? 'heroicon-m-exclamation-triangle' : 'heroicon-m-check-circle')
                ->color($lowStockProducts > 0 ? 'danger' : 'success'),

            Stat::make('Total Bahan Baku', \App\Models\RawMaterial::where('is_active', true)->count())
                ->description($lowStockRawMaterials > 0 ? "$lowStockRawMaterials stok menipis" : "Semua stok aman")
                ->descriptionIcon($lowStockRawMaterials > 0 ? 'heroicon-m-archive-box-arrow-down' : 'heroicon-m-check-circle')
                ->color($lowStockRawMaterials > 0 ? 'warning' : 'success'),

            Stat::make('Total Pengguna', $totalUsers)
                ->description('Kasir & Owner')
                ->descriptionIcon('heroicon-m-users')
                ->color('info'),
        ];
    }
}
