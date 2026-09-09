<?php

namespace App\Filament\Widgets;

use App\Models\Transaction;
use Carbon\Carbon;
use Filament\Widgets\ChartWidget;

class RevenueChartWidget extends ChartWidget
{
    protected ?string $heading = 'Pendapatan';
    protected int | string | array $columnSpan = 1;
    protected ?string $maxHeight = '400px';
    public static function getSort(): int { return 2; }

    protected function getFilters(): ?array
    {
        return [
            'daily'   => 'Harian (30 Hari)',
            'weekly'  => 'Mingguan (12 Minggu)',
            'monthly' => 'Bulanan (12 Bulan)',
        ];
    }

    protected function getData(): array
    {
        $filter = $this->filter ?? 'daily';
        $tenantId = \Filament\Facades\Filament::getTenant()?->id;
        $labels = [];
        $revenues = [];

        $baseQuery = Transaction::where('payment_status', 'paid');
        if ($tenantId) {
            $baseQuery->where('branch_id', $tenantId);
        }

        if ($filter === 'daily') {
            for ($i = 29; $i >= 0; $i--) {
                $date = Carbon::today()->subDays($i);
                $labels[] = $date->format('d M');
                $revenues[] = (float) (clone $baseQuery)->whereDate('created_at', $date)->sum('total');
            }
        } elseif ($filter === 'weekly') {
            for ($i = 11; $i >= 0; $i--) {
                $start = Carbon::now()->startOfWeek()->subWeeks($i);
                $end = (clone $start)->endOfWeek();
                $labels[] = $start->format('d M');
                $revenues[] = (float) (clone $baseQuery)->whereBetween('created_at', [$start, $end])->sum('total');
            }
        } else {
            for ($i = 11; $i >= 0; $i--) {
                $date = Carbon::now()->startOfMonth()->subMonths($i);
                $labels[] = $date->format('M Y');
                $revenues[] = (float) (clone $baseQuery)->whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)->sum('total');
            }
        }

        return [
            'datasets' => [[
                'label' => 'Pendapatan (Rp)',
                'data' => $revenues,
                'borderColor' => '#f59e0b',
                'backgroundColor' => 'rgba(245, 158, 11, 0.15)',
                'fill' => true,
                'tension' => 0.4,
                'pointBackgroundColor' => '#f59e0b',
                'pointRadius' => 3,
            ]],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
