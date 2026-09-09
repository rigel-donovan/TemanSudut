<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CashierShift;
use App\Models\Branch;
use Illuminate\Http\Request;

class ShiftController extends Controller
{
    public function current(Request $request)
    {
        $branchId = Branch::currentId($request);
        $shift = CashierShift::where('user_id', $request->user()->id)
            ->where('branch_id', $branchId)
            ->where('status', 'open')
            ->first();

        return response()->json([
            'status' => 'success',
            'data' => $shift
        ]);
    }

    public function open(Request $request)
    {
        $request->validate([
            'starting_cash' => 'required|numeric|min:0',
        ]);

        $branchId = Branch::currentId($request);
        $activeShift = CashierShift::where('user_id', $request->user()->id)
            ->where('branch_id', $branchId)
            ->where('status', 'open')
            ->first();

        if ($activeShift) {
            return response()->json([
                'status' => 'error',
                'message' => 'Anda masih memiliki shift yang terbuka di cabang ini.'
            ], 400);
        }

        $shift = CashierShift::create([
            'branch_id' => $branchId,
            'user_id' => $request->user()->id,
            'starting_cash' => $request->starting_cash,
            'status' => 'open',
            'opened_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Shift berhasil dibuka.',
            'data' => $shift
        ]);
    }

    public function close(Request $request)
    {
        $request->validate([
            'ending_cash' => 'nullable|numeric|min:0',
        ]);

        $branchId = Branch::currentId($request);
        $activeShift = CashierShift::where('user_id', $request->user()->id)
            ->where('branch_id', $branchId)
            ->where('status', 'open')
            ->first();

        if (!$activeShift) {
            return response()->json([
                'status' => 'error',
                'message' => 'Tidak ada shift yang sedang terbuka.'
            ], 400);
        }

        $activeShift->update([
            'status' => 'closed',
            'ending_cash' => $request->ending_cash ?? null,
            'closed_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Shift berhasil ditutup.',
            'data' => $activeShift
        ]);
    }
}
