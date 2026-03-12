<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;

use App\Models\ActivityLog;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with('category');
        
        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }
        
        return response()->json($query->get());
    }

    public function show(string $id)
    {
        $product = Product::with('category')->find($id);
        
        if (!$product) {
            return response()->json(['message' => 'Product not found'], 404);
        }
        
        return response()->json($product);
    }

    public function update(Request $request, string $id)
    {
        // Owner only — cashiers cannot change prices or stock
        if (auth()->user()->isCashier()) {
            return response()->json(['message' => 'Akses ditolak. Hanya owner yang bisa mengubah data produk.'], 403);
        }

        $product = Product::find($id);
        
        if (!$product) {
            return response()->json(['message' => 'Product not found'], 404);
        }
        
        $request->validate([
            'stock' => 'sometimes|integer|min:0',
            'price' => 'sometimes|numeric|min:0',
        ]);

        $oldStock = $product->stock;
        $oldPrice = $product->price;
        
        $product->update($request->only(['stock', 'price', 'is_active']));

        // Audit Log
        ActivityLog::log('product_updated', 'Produk "' . $product->name . '" diubah oleh ' . auth()->user()->name, [
            'product_id' => $product->id,
            'old_stock' => $oldStock,
            'new_stock' => $product->stock,
            'old_price' => $oldPrice,
            'new_price' => $product->price,
        ]);
        
        return response()->json($product);
    }
}
