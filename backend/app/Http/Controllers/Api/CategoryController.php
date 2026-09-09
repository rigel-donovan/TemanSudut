<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Category;
use App\Models\Branch;

class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $branchId = Branch::currentId($request);
        return response()->json(Category::where('branch_id', $branchId)->get());
    }
}
