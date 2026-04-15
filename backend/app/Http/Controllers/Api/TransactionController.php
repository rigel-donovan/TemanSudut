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
    /**
     * Get compressed logo as base64 for PDF embedding.
     * Resizes to max 150px and compresses to JPEG quality 60.
     */
    private function getCompressedLogoBase64(int $maxSize = 150, int $quality = 60): string
    {
        $logoPath = public_path('images/logo.png');
        if (!file_exists($logoPath)) return '';

        $info = getimagesize($logoPath);
        if (!$info) return '';

        $src = imagecreatefrompng($logoPath);
        if (!$src) return '';

        $origW = imagesx($src);
        $origH = imagesy($src);
        $ratio = min($maxSize / $origW, $maxSize / $origH, 1);
        $newW = (int) round($origW * $ratio);
        $newH = (int) round($origH * $ratio);

        $dst = imagecreatetruecolor($newW, $newH);
        // Preserve transparency as white background
        $white = imagecolorallocate($dst, 255, 255, 255);
        imagefill($dst, 0, 0, $white);
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $newW, $newH, $origW, $origH);
        imagedestroy($src);

        ob_start();
        imagejpeg($dst, null, $quality);
        $data = ob_get_clean();
        imagedestroy($dst);

        return 'data:image/jpeg;base64,' . base64_encode($data);
    }
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
            'items.*.extra_charge' => 'nullable|numeric',
            'amount_received' => 'nullable|numeric',
            'change_amount' => 'nullable|numeric',
            'completion_photo' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120',
            'completion_photo_base64' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            // ── Fix N+1: Load all products in ONE query ──────────────────────
            $productIds = array_column($validated['items'], 'product_id');
            $productMap = Product::with('ingredients.rawMaterial')->whereIn('id', $productIds)->get()->keyBy('id');

            // ── Validate ingredient stock sufficiency ────────────────────────
            $shortages = [];
            foreach ($validated['items'] as $item) {
                $product = $productMap[$item['product_id']];
                foreach ($product->ingredients as $ingredient) {
                    if (!$ingredient->rawMaterial) continue;
                    $needed = $ingredient->quantity_used * $item['quantity'];
                    $available = (float) $ingredient->rawMaterial->stock;
                    if ($needed > $available) {
                        $shortages[] = [
                            'product' => $product->name,
                            'ingredient' => $ingredient->rawMaterial->name,
                            'needed' => $needed,
                            'available' => $available,
                            'unit' => $ingredient->rawMaterial->unit_small ?? $ingredient->rawMaterial->unit,
                        ];
                    }
                }
            }

            if (!empty($shortages)) {
                DB::rollBack();
                $messages = array_map(fn($s) =>
                    "{$s['ingredient']}: butuh {$s['needed']} {$s['unit']}, tersedia {$s['available']} {$s['unit']} (untuk {$s['product']})",
                    $shortages
                );
                return response()->json([
                    'message' => 'Stok bahan baku tidak mencukupi',
                    'shortages' => $shortages,
                    'details' => $messages,
                ], 422);
            }

            $subtotal = 0;
            $items = [];

            foreach ($validated['items'] as $item) {
                $product = $productMap[$item['product_id']];
                $extraCharge = floatval($item['extra_charge'] ?? 0);
                $itemSubtotal = ($product->price + $extraCharge) * $item['quantity'];
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
                    'extra_charge' => $extraCharge,
                ];
            }

            $tax = 0;
            $total = $subtotal + $tax;

            $transaction = Transaction::create([
                'user_id' => auth()->id(),
                'order_type' => $validated['order_type'],
                'customer_name' => $validated['customer_name'] ?? null,
                'subtotal' => $subtotal,
                'tax' => $tax,
                'total' => $total,
                'payment_method' => $validated['payment_method'],
                'payment_status' => 'unpaid',
                'kitchen_status' => 'pending',
                'notes' => $validated['notes'] ?? null,
                'amount_received' => $validated['amount_received'] ?? null,
                'change_amount' => $validated['change_amount'] ?? null,
            ]);

            // Handle Photo Saving
            if ($request->hasFile('completion_photo')) {
                File::ensureDirectoryExists(storage_path('app/public/completion_photos'));
                $path = $request->file('completion_photo')->store('completion_photos', 'public');
                $url = url(\Storage::disk('public')->url($path));
                $transaction->update(['completion_photo' => $url]);
            }
            elseif ($request->filled('completion_photo_base64')) {
                $imageData = $request->completion_photo_base64;
                if (preg_match('/^data:image\/(\w+);base64,/', $imageData, $type)) {
                    $imageData = substr($imageData, strpos($imageData, ',') + 1);
                    $type = strtolower($type[1]);
                }
                else {
                    $type = 'jpg';
                }
                $imageData = base64_decode($imageData);
                $fileName = 'completion_' . $transaction->id . '_' . time() . '.' . $type;
                File::ensureDirectoryExists(storage_path('app/public/completion_photos'));
                $path = 'completion_photos/' . $fileName;
                \Storage::disk('public')->put($path, $imageData);
                $url = url(\Storage::disk('public')->url($path));
                $transaction->update(['completion_photo' => $url]);
            }

            $now = now();
            TransactionItem::insert(array_map(fn($item) => array_merge($item, [
            'transaction_id' => $transaction->id,
            'created_at' => $now,
            'updated_at' => $now,
            ]), $items));

            foreach ($validated['items'] as $item) {
                $product = $productMap[$item['product_id']];
                $product->load('ingredients.rawMaterial');

                foreach ($product->ingredients as $ingredient) {
                    $totalUsed = $ingredient->quantity_used * $item['quantity'];
                    \App\Models\RawMaterial::adjustStock(
                        $ingredient->raw_material_id,
                        -$totalUsed,
                        'order_deduction',
                        'Pesanan #' . $transaction->id . ' - ' . $product->name . ' x' . $item['quantity'],
                        null,
                        auth()->id()
                    );
                }
            }

            ActivityLog::log('order_created', 'Pesanan #' . $transaction->id . ' dibuat oleh ' . (auth()->user()->name ?? 'System'), [
                'transaction_id' => $transaction->id,
                'total' => $total,
                'customer_name' => $validated['customer_name'] ?? 'Tamu',
                'items_count' => count($items),
                'has_photo' => !empty($transaction->completion_photo),
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Transaction successful',
                'transaction' => $transaction->load('items.product')
            ], 201);

        }
        catch (\Exception $e) {
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
        }
        elseif ($filter === 'weekly') {
            $query->whereDate('created_at', '>=', now()->startOfWeek()->toDateString())
                ->whereDate('created_at', '<=', now()->endOfWeek()->toDateString());
        }
        elseif ($filter === 'monthly') {
            $query->whereDate('created_at', '>=', now()->startOfMonth()->toDateString())
                ->whereDate('created_at', '<=', now()->endOfMonth()->toDateString());
        }
        elseif ($filter && str_starts_with($filter, 'date:')) {
            $date = substr($filter, 5);
            $query->whereDate('created_at', $date);
        }

        return $query->orderBy('created_at', 'desc');
    }

    public function history(Request $request)
    {
        // Cap at 500 records per query — enough for daily/weekly/monthly reports
        $transactions = $this->getFilteredHistoryQuery($request->query('filter'))->limit(500)->get();
        return response()->json($transactions);
    }

    private function resolveUser(Request $request)
    {
        $user = auth('sanctum')->user();

        if (!$user && $request->filled('token')) {
            $token = \Laravel\Sanctum\PersonalAccessToken::findToken($request->token);
            if ($token) {
                $user = $token->tokenable;
            }
        }

        return $user;
    }

    public function exportExcel(Request $request)
    {
        ini_set('memory_limit', '256M');
        set_time_limit(120);

        $user = $this->resolveUser($request);

        if (!$user) {
            return response()->json(['message' => 'Akses ditolak. Silakan login kembali.'], 401);
        }

        if (!\App\Models\RolePermission::isAllowed('export_history', $user->role)) {
            return response()->json(['message' => 'Akses ditolak. Anda tidak memiliki izin untuk export.'], 403);
        }

        try {
            $transactions = $this->getFilteredHistoryQuery($request->query('filter'))->limit(2000)->get();
            return \Maatwebsite\Excel\Facades\Excel::download(new \App\Exports\HistoryExport($transactions), 'history_transactions.xlsx');
        } catch (\Exception $e) {
            return response()->json(['message' => 'Export gagal: ' . $e->getMessage()], 500);
        }
    }

    public function exportPdf(Request $request)
    {
        ini_set('memory_limit', '256M');
        set_time_limit(120);

        $user = $this->resolveUser($request);

        if (!$user) {
            return response()->json(['message' => 'Akses ditolak. Silakan login kembali.'], 401);
        }

        if (!\App\Models\RolePermission::isAllowed('export_history', $user->role)) {
            return response()->json(['message' => 'Akses ditolak. Anda tidak memiliki izin untuk export.'], 403);
        }

        try {
            // Limit PDF to 500 rows — DomPDF can't handle very large tables
            $transactions = $this->getFilteredHistoryQuery($request->query('filter'))->limit(500)->get();

            $totalProcessed = $transactions->sum('total');
            $startDate = $transactions->min('created_at');
            $endDate = $transactions->max('created_at');
            $generatedOn = now();

            $logoBase64 = $this->getCompressedLogoBase64();

            $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('exports.history_pdf', [
                'transactions' => $transactions,
                'totalProcessed' => $totalProcessed,
                'startDate' => $startDate,
                'endDate' => $endDate,
                'generatedOn' => $generatedOn,
                'logoBase64' => $logoBase64,
                'totalCount' => $transactions->count(),
            ]);

            $pdf->setPaper('A4', 'landscape');

            return $pdf->download('history_transactions.pdf');
        } catch (\Exception $e) {
            return response()->json(['message' => 'Export PDF gagal: ' . $e->getMessage()], 500);
        }
    }

    public function exportReceiptPdf(Request $request, $id)
    {
        $user = $this->resolveUser($request);

        if (!$user) {
            return response()->json(['message' => 'Akses ditolak. Silakan login kembali.'], 401);
        }

        $transaction = Transaction::with(['items.product', 'user', 'table'])->findOrFail($id);

        $logoBase64 = $this->getCompressedLogoBase64();

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('exports.receipt_80mm', [
            'transaction' => $transaction,
            'logoBase64' => $logoBase64,
        ]);

        $itemCount = $transaction->items->count();
        $baseHeight = 550;  
        $perItemHeight = 75; 
        $calculatedHeight = $baseHeight + ($itemCount * $perItemHeight);
        $minHeight = 600; 
        $pageHeight = max($minHeight, $calculatedHeight);

        $pdf->setPaper([0, 0, 226.77, $pageHeight], 'portrait');

        return $pdf->stream('receipt-' . $id . '.pdf');
    }

    public function activeOrders()
    {
        $transactions = Transaction::with(['items.product:id,name,price', 'table:id,name', 'user:id,name'])
            ->whereIn('kitchen_status', ['pending', 'processing'])
            ->orderBy('created_at', 'asc')
            ->limit(200)
            ->get();

        return response()->json($transactions);
    }

    public function updateStatus(Request $request, $id)
    {
        $transaction = Transaction::findOrFail($id);

        $rules = [
            'kitchen_status' => 'required|in:pending,processing,completed',
            'order_type' => 'nullable|in:dine_in,take_away,online',
            'amount_received' => 'nullable|numeric',
            'change_amount' => 'nullable|numeric',
        ];

        // If status is completed, either completion_photo or completion_photo_base64 must be present
        if ($request->kitchen_status === 'completed') {
            $rules['completion_photo'] = 'required_without:completion_photo_base64|nullable|image|mimes:jpeg,png,jpg,webp|max:5120';
            $rules['completion_photo_base64'] = 'required_without:completion_photo|nullable|string';
        }

        $validated = $request->validate($rules);

        $oldStatus = $transaction->kitchen_status;
        $updateData = [
            'kitchen_status' => $validated['kitchen_status'],
            'amount_received' => $validated['amount_received'] ?? $transaction->amount_received,
            'change_amount' => $validated['change_amount'] ?? $transaction->change_amount,
        ];

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
            }
            else {
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

    public function destroy($id)
    {
        $transaction = Transaction::with('items')->findOrFail($id);

        if ($transaction->payment_status === 'paid') {
            return response()->json(['message' => 'Pesanan yang sudah dibayar tidak dapat dihapus'], 400);
        }

        try {
            DB::beginTransaction();

            foreach ($transaction->items as $item) {
                $product = Product::find($item->product_id);
                if ($product) {
                    $product->increment('stock', $item->quantity);
                }
            }

            ActivityLog::log('order_deleted', 'Pesanan #' . $transaction->id . ' dihapus oleh ' . (auth()->user()->name ?? 'System'));

            $transaction->delete();
            DB::commit();

            return response()->json(['message' => 'Pesanan berhasil dihapus']);
        }
        catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal menghapus pesanan', 'error' => $e->getMessage()], 500);
        }
    }
}
