<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Transaction;
use App\Models\TransactionItem;
use App\Models\Product;
use App\Models\ActivityLog;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class TransactionController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'payment_method' => 'required|string',
            'order_type' => 'required|in:dine_in,take_away,online',
            'customer_name' => 'nullable|string',
            'notes' => 'nullable|string',
            'items' => 'required|array',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.notes' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            $subtotal = 0;
            $items = [];

            foreach ($validated['items'] as $item) {
                $product = Product::find($item['product_id']);
                $itemSubtotal = $product->price * $item['quantity'];
                $subtotal += $itemSubtotal;

                if ($product->stock >= $item['quantity']) {
                    $product->decrement('stock', $item['quantity']);
                }

                $items[] = [
                    'product_id' => $product->id,
                    'quantity' => $item['quantity'],
                    'unit_price' => $product->price,
                    'subtotal' => $itemSubtotal,
                    'notes' => $item['notes'] ?? null,
                ];
            }

            $tax = 0;
            $total = $subtotal + $tax;

            $transaction = Transaction::create([
                'user_id' => auth()->id(), // Track which cashier created the order
                'order_type' => $validated['order_type'],
                'customer_name' => $validated['customer_name'] ?? null,
                'subtotal' => $subtotal,
                'tax' => $tax,
                'total' => $total,
                'payment_method' => $validated['payment_method'],
                'payment_status' => 'unpaid',
                'kitchen_status' => 'pending',
                'notes' => $validated['notes'] ?? null,
            ]);

            foreach ($items as $item) {
                $item['transaction_id'] = $transaction->id;
                TransactionItem::create($item);
            }

            // Audit Log
            ActivityLog::log('order_created', 'Pesanan #' . $transaction->id . ' dibuat oleh ' . (auth()->user()->name ?? 'System'), [
                'transaction_id' => $transaction->id,
                'total' => $total,
                'customer_name' => $validated['customer_name'] ?? 'Tamu',
                'items_count' => count($items),
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Transaction successful',
                'transaction' => $transaction->load('items.product')
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Transaction failed', 'error' => $e->getMessage()], 500);
        }
    }

    private function getFilteredHistoryQuery($filter)
    {
        $query = Transaction::with(['items.product', 'table', 'user'])
            ->where('kitchen_status', 'completed');
        
        if ($filter === 'daily') {
            $query->whereDate('created_at', now()->toDateString());
        } elseif ($filter === 'weekly') {
            $query->whereDate('created_at', '>=', now()->startOfWeek()->toDateString())
                  ->whereDate('created_at', '<=', now()->endOfWeek()->toDateString());
        } elseif ($filter === 'monthly') {
            $query->whereDate('created_at', '>=', now()->startOfMonth()->toDateString())
                  ->whereDate('created_at', '<=', now()->endOfMonth()->toDateString());
        } elseif ($filter && str_starts_with($filter, 'date:')) {
            $date = substr($filter, 5);
            $query->whereDate('created_at', $date);
        }
        
        return $query->orderBy('created_at', 'desc');
    }

    public function history(Request $request)
    {
        $transactions = $this->getFilteredHistoryQuery($request->query('filter'))->get();
        return response()->json($transactions);
    }

    public function exportExcel(Request $request)
    {
        // Owner only
        if (auth()->user()->isCashier()) {
            return response()->json(['message' => 'Akses ditolak. Hanya owner yang bisa export.'], 403);
        }

        $transactions = $this->getFilteredHistoryQuery($request->query('filter'))->get();
        return \Maatwebsite\Excel\Facades\Excel::download(new \App\Exports\HistoryExport($transactions), 'history_transactions.xlsx');
    }

    public function exportPdf(Request $request)
    {
        // Owner only
        if (auth()->user()->isCashier()) {
            return response()->json(['message' => 'Akses ditolak. Hanya owner yang bisa export.'], 403);
        }

        $transactions = $this->getFilteredHistoryQuery($request->query('filter'))->get();
        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('exports.history_pdf', ['transactions' => $transactions]);
        return $pdf->download('history_transactions.pdf');
    }

    public function activeOrders()
    {
        $transactions = Transaction::with(['items.product', 'table', 'user'])
            ->whereIn('kitchen_status', ['pending', 'processing'])
            ->orderBy('created_at', 'asc')
            ->get();
            
        return response()->json($transactions);
    }

    public function updateStatus(Request $request, $id)
    {
        $transaction = Transaction::findOrFail($id);
        
        $rules = [
            'kitchen_status' => 'required|in:pending,processing,completed',
            'order_type' => 'nullable|in:dine_in,take_away,online',
        ];

        // If status is completed, either completion_photo or completion_photo_base64 must be present
        if ($request->kitchen_status === 'completed') {
            $rules['completion_photo'] = 'required_without:completion_photo_base64|nullable|image|mimes:jpeg,png,jpg,webp|max:5120';
            $rules['completion_photo_base64'] = 'required_without:completion_photo|nullable|string';
        }

        $validated = $request->validate($rules);
        
        $oldStatus = $transaction->kitchen_status;
        $updateData = ['kitchen_status' => $validated['kitchen_status']];

        // Save order_type if provided (set during order completion)
        if ($request->filled('order_type')) {
            $updateData['order_type'] = $request->input('order_type');
        }

        if ($validated['kitchen_status'] === 'completed') {
            $updateData['payment_status'] = 'paid';
        }

        // Handle File upload
        if ($request->hasFile('completion_photo')) {
            if ($transaction->completion_photo) {
                $oldPath = str_replace(url('/storage'), 'public', $transaction->completion_photo);
                \Storage::delete($oldPath);
            }
            File::ensureDirectoryExists(storage_path('app/public/completion_photos'));
            $path = $request->file('completion_photo')->store('completion_photos', 'public');
            $updateData['completion_photo'] = url(\Storage::disk('public')->url($path));
        } 
        // Handle Base64 upload
        elseif ($request->filled('completion_photo_base64')) {
            if ($transaction->completion_photo) {
                $oldPath = str_replace(url('/storage'), 'public', $transaction->completion_photo);
                \Storage::delete($oldPath);
            }

            $imageData = $request->completion_photo_base64;
            // Strip data:image/png;base64, if it exists
            if (preg_match('/^data:image\/(\w+);base64,/', $imageData, $type)) {
                $imageData = substr($imageData, strpos($imageData, ',') + 1);
                $type = strtolower($type[1]); // jpg, png, etc
            } else {
                $type = 'jpg'; // Default
            }

            $imageData = base64_decode($imageData);
            $fileName = 'completion_' . $id . '_' . time() . '.' . $type;
            File::ensureDirectoryExists(storage_path('app/public/completion_photos'));
            $path = 'completion_photos/' . $fileName;
            
            \Storage::disk('public')->put($path, $imageData);
            $updateData['completion_photo'] = url(\Storage::disk('public')->url($path));
        }

        $transaction->update($updateData);

        // Audit Log
        ActivityLog::log('order_status_updated', 'Status pesanan #' . $transaction->id . ' diubah dari ' . $oldStatus . ' ke ' . $validated['kitchen_status'], [
            'transaction_id' => $transaction->id,
            'old_status' => $oldStatus,
            'new_status' => $validated['kitchen_status'],
            'has_photo' => $request->hasFile('completion_photo'),
        ]);
        
        return response()->json([
            'message' => 'Status updated', 
            'transaction' => $transaction->load('items.product')
        ]);
    }
}
