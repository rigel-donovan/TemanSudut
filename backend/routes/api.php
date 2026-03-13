<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\TableController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ShiftController;
use App\Http\Controllers\Api\PermissionController;
use App\Http\Controllers\Api\RawMaterialController;

Route::post('/login', [AuthController::class, 'login']);

Route::get('/permissions', [PermissionController::class, 'index']);

Route::get('/images/{path}', function ($path) {
    if (\Storage::disk('local')->exists($path)) {
        $file = \Storage::disk('local')->get($path);
        $mime = \Storage::disk('local')->mimeType($path);
        return response($file, 200)->header('Content-Type', $mime);
    }
    
    if (\Storage::disk('public')->exists($path)) {
        $file = \Storage::disk('public')->get($path);
        $mime = \Storage::disk('public')->mimeType($path);
        return response($file, 200)->header('Content-Type', $mime);
    }
    
    abort(404);
})->where('path', '.*');


    // Categories
    Route::get('/categories', [CategoryController::class, 'index']);

    // Products
    Route::get('/products', [ProductController::class, 'index']);
    Route::get('/products/{id}', [ProductController::class, 'show']);

    // Tables
    Route::get('/tables', [TableController::class, 'index']);
    Route::get('/tables/available', [TableController::class, 'available']);

    Route::get('/transactions/export/excel', [TransactionController::class, 'exportExcel']);
Route::get('/transactions/export/pdf', [TransactionController::class, 'exportPdf']);
Route::get('/transactions/{id}/receipt', [TransactionController::class, 'exportReceiptPdf']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'me']);
    
    // Shifts
    Route::get('/shifts/current', [ShiftController::class, 'current']);
    Route::post('/shifts/open', [ShiftController::class, 'open']);
    Route::post('/shifts/close', [ShiftController::class, 'close']);
    
    // Transactions
    Route::post('/transactions', [TransactionController::class, 'store']);
    Route::get('/transactions/active', [TransactionController::class, 'activeOrders']);
    Route::put('/transactions/{id}/status', [TransactionController::class, 'updateStatus']);
    Route::post('/transactions/{id}/status', [TransactionController::class, 'updateStatus']);
    Route::get('/transactions/history', [TransactionController::class, 'history']);
    
    // Products (update = owner only, enforced in controller)
    Route::put('/products/{id}', [ProductController::class, 'update']);

    // User Management (owner only, enforced in controller)
    Route::get('/users', [\App\Http\Controllers\Api\UserController::class, 'index']);
    Route::post('/users', [\App\Http\Controllers\Api\UserController::class, 'store']);
    Route::put('/users/{id}', [\App\Http\Controllers\Api\UserController::class, 'update']);
    Route::delete('/users/{id}', [\App\Http\Controllers\Api\UserController::class, 'destroy']);

    // Raw Materials
    Route::get('/raw-materials', [RawMaterialController::class, 'index']);
    Route::put('/raw-materials/{id}', [RawMaterialController::class, 'update']);
});
