<?php

namespace App\Filament\Widgets;

use App\Models\FinanceEntry;
use Carbon\Carbon;
use Filament\Widgets\ChartWidget;

class FinanceChartWidget extends ChartWidget
{
    protected ?string $heading = 'Pemasukan & Pengeluaran';
    protected int | string | array $columnSpan = 'full';
    protected ?string $maxHeight = '350px';
    public static function getSort(): int { return 4; }

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
        $incomes = [];
        $expenses = [];

        if ($filter === 'daily') {
            for ($i = 29; $i >= 0; $i--) {
                $date = Carbon::today()->subDays($i);
                $labels[]   = $date->format('d M');
                $incomes[]  = (float) FinanceEntry::where('type', 'income')->whereDate('date', $date)->sum('amount');
                $expenses[] = (float) FinanceEntry::where('type', 'expense')->whereDate('date', $date)->sum('amount');
            }
        } elseif ($filter === 'weekly') {
            for ($i = 11; $i >= 0; $i--) {
                $start      = Carbon::now()->startOfWeek()->subWeeks($i);
                $end        = (clone $start)->endOfWeek();
                $labels[]   = $start->format('d M');
                $incomes[]  = (float) FinanceEntry::where('type', 'income')->whereBetween('date', [$start->toDateString(), $end->toDateString()])->sum('amount');
                $expenses[] = (float) FinanceEntry::where('type', 'expense')->whereBetween('date', [$start->toDateString(), $end->toDateString()])->sum('amount');
            }
        } else {
            // monthly
            for ($i = 11; $i >= 0; $i--) {
                $date       = Carbon::now()->startOfMonth()->subMonths($i);
                $labels[]   = $date->format('M Y');
                $incomes[]  = (float) FinanceEntry::where('type', 'income')->whereYear('date', $date->year)->whereMonth('date', $date->month)->sum('amount');
                $expenses[] = (float) FinanceEntry::where('type', 'expense')->whereYear('date', $date->year)->whereMonth('date', $date->month)->sum('amount');
            }
        }

        return [
            'datasets' => [
                [
                    'label'           => 'Pemasukan (Rp)',
                    'data'            => $incomes,
                    'borderColor'     => '#22c55e',
                    'backgroundColor' => 'rgba(34, 197, 94, 0.15)',
                    'fill'            => true,
                    'tension'         => 0.4,
                    'pointBackgroundColor' => '#22c55e',
                    'pointRadius'     => 3,
                ],
                [
                    'label'           => 'Pengeluaran (Rp)',
                    'data'            => $expenses,
                    'borderColor'     => '#ef4444',
                    'backgroundColor' => 'rgba(239, 68, 68, 0.10)',
                    'fill'            => true,
                    'tension'         => 0.4,
                    'pointBackgroundColor' => '#ef4444',
                    'pointRadius'     => 3,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
