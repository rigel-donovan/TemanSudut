<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FinanceEntry;
use Illuminate\Http\Request;
use Carbon\Carbon;

class FinanceController extends Controller
{
    /** GET /finance-entries */
    public function index(Request $request)
    {
        $query = FinanceEntry::with('user:id,name')->orderBy('date', 'desc');

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('filter')) {
            $filter = $request->filter;
            if ($filter === 'daily') {
                $query->whereDate('date', now()->toDateString());
            } elseif ($filter === 'weekly') {
                $query->whereBetween('date', [now()->startOfWeek()->toDateString(), now()->endOfWeek()->toDateString()]);
            } elseif ($filter === 'monthly') {
                $query->whereMonth('date', now()->month)->whereYear('date', now()->year);
            }
        }

        return response()->json($query->limit(500)->get());
    }

    /** POST /finance-entries */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'type'        => 'required|in:income,expense',
            'category'    => 'nullable|string|max:100',
            'description' => 'required|string|max:255',
            'amount'      => 'required|numeric|min:1',
            'date'        => 'required|date',
            'notes'       => 'nullable|string|max:500',
        ]);

        $entry = FinanceEntry::create(array_merge($validated, ['user_id' => auth()->id()]));

        return response()->json($entry->load('user:id,name'), 201);
    }

    /** PUT /finance-entries/{id} */
    public function update(Request $request, $id)
    {
        $entry = FinanceEntry::findOrFail($id);

        $validated = $request->validate([
            'type'        => 'sometimes|in:income,expense',
            'category'    => 'nullable|string|max:100',
            'description' => 'sometimes|string|max:255',
            'amount'      => 'sometimes|numeric|min:1',
            'date'        => 'sometimes|date',
            'notes'       => 'nullable|string|max:500',
        ]);

        $entry->update($validated);

        return response()->json($entry->load('user:id,name'));
    }

    /** DELETE /finance-entries/{id} */
    public function destroy($id)
    {
        FinanceEntry::findOrFail($id)->delete();
        return response()->json(['message' => 'Catatan berhasil dihapus']);
    }

    /** GET /finance-entries/summary — total income, total expense, net */
    public function summary(Request $request)
    {
        $filter = $request->filter ?? 'monthly';
        $query = FinanceEntry::query();

        if ($filter === 'daily') {
            $query->whereDate('date', now()->toDateString());
        } elseif ($filter === 'weekly') {
            $query->whereBetween('date', [now()->startOfWeek()->toDateString(), now()->endOfWeek()->toDateString()]);
        } else {
            // monthly (default)
            $query->whereMonth('date', now()->month)->whereYear('date', now()->year);
        }

        $income  = (float) (clone $query)->where('type', 'income')->sum('amount');
        $expense = (float) (clone $query)->where('type', 'expense')->sum('amount');

        return response()->json([
            'income'  => $income,
            'expense' => $expense,
            'net'     => $income - $expense,
            'filter'  => $filter,
        ]);
    }

    /** GET /finance-entries/chart?period=daily|weekly|monthly — data for line chart */
    public function chart(Request $request)
    {
        $period = $request->period ?? 'daily';
        $labels = [];
        $incomes = [];
        $expenses = [];

        if ($period === 'daily') {
            for ($i = 29; $i >= 0; $i--) {
                $date = Carbon::today()->subDays($i);
                $labels[]   = $date->format('d/m');
                $incomes[]  = (float) FinanceEntry::where('type', 'income')->whereDate('date', $date)->sum('amount');
                $expenses[] = (float) FinanceEntry::where('type', 'expense')->whereDate('date', $date)->sum('amount');
            }
        } elseif ($period === 'weekly') {
            for ($i = 11; $i >= 0; $i--) {
                $start = Carbon::now()->startOfWeek()->subWeeks($i);
                $end   = (clone $start)->endOfWeek();
                $labels[]   = $start->format('d/m');
                $incomes[]  = (float) FinanceEntry::where('type', 'income')->whereBetween('date', [$start->toDateString(), $end->toDateString()])->sum('amount');
                $expenses[] = (float) FinanceEntry::where('type', 'expense')->whereBetween('date', [$start->toDateString(), $end->toDateString()])->sum('amount');
            }
        } else {
            for ($i = 11; $i >= 0; $i--) {
                $date = Carbon::now()->startOfMonth()->subMonths($i);
                $labels[]   = $date->format('M y');
                $incomes[]  = (float) FinanceEntry::where('type', 'income')->whereYear('date', $date->year)->whereMonth('date', $date->month)->sum('amount');
                $expenses[] = (float) FinanceEntry::where('type', 'expense')->whereYear('date', $date->year)->whereMonth('date', $date->month)->sum('amount');
            }
        }

        return response()->json(['labels' => $labels, 'incomes' => $incomes, 'expenses' => $expenses]);
    }
}
