<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RawMaterial;
use App\Models\RolePermission;
use Illuminate\Http\Request;

class RawMaterialController extends Controller
{
    public function index()
    {
        return response()->json(RawMaterial::where('is_active', true)->get());
    }

    public function update(Request $request, string $id)
    {
        if (!RolePermission::isAllowed('manage_stock', auth()->user()->role)) {
            return response()->json(['message' => 'Akses ditolak. Anda tidak memiliki izin untuk mengelola stok.'], 403);
        }

        $material = RawMaterial::find($id);
        
        if (!$material) {
            return response()->json(['message' => 'Bahan baku tidak ditemukan'], 404);
        }
        
        $request->validate([
            'name'  => 'sometimes|string|max:255',
            'unit'  => 'sometimes|string|max:255',
            'stock' => 'sometimes|numeric|min:0',
        ]);

        $oldStock = (float) $material->stock;
        
        $material->update($request->only(['name', 'unit', 'stock', 'is_active']));

        // Logging is handled by adjustStock usually, but if updated via Request directly:
        // RawMaterial::adjustStock($id, $request->stock - $oldStock, 'adjustment', 'Update via App');
        
        return response()->json($material);
    }
}
