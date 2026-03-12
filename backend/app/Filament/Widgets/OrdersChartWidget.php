<?php

namespace App\Filament\Widgets;

use App\Models\Transaction;
use Carbon\Carbon;
use Filament\Widgets\ChartWidget;

class OrdersChartWidget extends ChartWidget
{
    protected ?string $heading = 'Jumlah Order';
    protected int | string | array $columnSpan = 1;
    protected ?string $maxHeight = '400px';
    public static function getSort(): int { return 3; }

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
        $labels = [];
        $counts = [];

        if ($filter === 'daily') {
            for ($i = 29; $i >= 0; $i--) {
                $date = Carbon::today()->subDays($i);
                $labels[] = $date->format('d M');
                $counts[] = Transaction::whereDate('created_at', $date)->count();
            }
        } elseif ($filter === 'weekly') {
            for ($i = 11; $i >= 0; $i--) {
                $start = Carbon::now()->startOfWeek()->subWeeks($i);
                $end = (clone $start)->endOfWeek();
                $labels[] = $start->format('d M');
                $counts[] = Transaction::whereBetween('created_at', [$start, $end])->count();
            }
        } else {
            for ($i = 11; $i >= 0; $i--) {
                $date = Carbon::now()->startOfMonth()->subMonths($i);
                $labels[] = $date->format('M Y');
                $counts[] = Transaction::whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)->count();
            }
        }

        return [
            'datasets' => [[
                'label' => 'Jumlah Order',
                'data' => $counts,
                'backgroundColor' => 'rgba(245, 158, 11, 0.7)',
                'borderColor' => '#f59e0b',
                'borderWidth' => 1,
                'borderRadius' => 4,
            ]],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
