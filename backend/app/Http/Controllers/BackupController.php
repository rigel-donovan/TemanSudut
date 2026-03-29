<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class BackupController extends Controller
{
    public function download(Request $request)
    {
        if (!Auth::check()) {
            abort(403, 'Unauthorized');
        }

        $dbPath = database_path('database.sqlite');

        if (!file_exists($dbPath)) {
            abort(404, 'File database tidak ditemukan.');
        }

        $fileName = 'backup-kasir-' . now()->format('Y-m-d') . '.sqlite';

        return response()->download($dbPath, $fileName, [
            'Content-Type' => 'application/octet-stream',
        ]);
    }
}
