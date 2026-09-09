<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Table;
use App\Models\Branch;

class TableController extends Controller
{
    public function index(Request $request)
    {
        $branchId = Branch::currentId($request);
        return response()->json(Table::where('branch_id', $branchId)->get());
    }

    public function available(Request $request)
    {
        $branchId = Branch::currentId($request);
        return response()->json(Table::where('branch_id', $branchId)->where('status', 'available')->get());
    }
}
