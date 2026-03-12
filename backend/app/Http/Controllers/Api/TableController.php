<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Table;

class TableController extends Controller
{
    public function index()
    {
        return response()->json(Table::all());
    }

    public function available()
    {
        return response()->json(Table::where('status', 'available')->get());
    }
}
