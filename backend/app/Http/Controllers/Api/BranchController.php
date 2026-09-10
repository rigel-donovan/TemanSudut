<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Branch;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductIngredient;
use App\Models\RawMaterial;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BranchController extends Controller
{
    /**
     * GET /api/branches
     * Return branches accessible to the user (or all active branches for login screen/owner).
     */
    public function index(Request $request)
    {
        $user = $request->user();

        try {
            if (!\Illuminate\Support\Facades\Schema::hasTable('branches')) {
                return response()->json([
                    'status' => 'success',
                    'data' => [
                        [
                            'id' => 1,
                            'name' => 'Cabang Ring Road',
                            'address' => 'Pusat',
                            'phone' => null,
                            'is_active' => true,
                        ]
                    ],
                ]);
            }

            if (!$user || $user->isOwner()) {
                $branches = Branch::where('is_active', true)->orderBy('id', 'asc')->get();
            } else {
                $branches = $user->branches()->where('is_active', true)->orderBy('id', 'asc')->get();
                if ($branches->isEmpty()) {
                    // Fallback to default branch
                    $branches = Branch::where('id', 1)->get();
                }
            }

            if ($branches->isEmpty()) {
                $branches = [
                    [
                        'id' => 1,
                        'name' => 'Cabang Ring Road',
                        'address' => 'Pusat',
                        'phone' => null,
                        'is_active' => true,
                    ]
                ];
            }
        } catch (\Throwable $e) {
            $branches = [
                [
                    'id' => 1,
                    'name' => 'Cabang Ring Road',
                    'address' => 'Pusat',
                    'phone' => null,
                    'is_active' => true,
                ]
            ];
        }

        return response()->json([
            'status' => 'success',
            'data' => $branches,
        ]);
    }

    /**
     * POST /api/branches
     * Create a new branch (Owner only).
     */
    public function store(Request $request)
    {
        if (!$request->user()->isOwner()) {
            return response()->json(['message' => 'Hanya Owner yang dapat menambah cabang.'], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'address' => 'nullable|string|max:500',
            'phone' => 'nullable|string|max:50',
        ]);

        $branch = Branch::create([
            'name' => $validated['name'],
            'address' => $validated['address'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'is_active' => true,
        ]);

        // Attach to owner
        $request->user()->branches()->syncWithoutDetaching([$branch->id]);

        return response()->json([
            'status' => 'success',
            'message' => 'Cabang berhasil dibuat.',
            'data' => $branch,
        ], 201);
    }

    /**
     * POST /api/branches/{id}/clone-catalog
     * Copy categories and products from a source branch to this target branch.
     */
    public function cloneCatalog(Request $request, int $id)
    {
        if (!$request->user()->isOwner()) {
            return response()->json(['message' => 'Hanya Owner yang dapat menyalin katalog.'], 403);
        }

        $targetBranch = Branch::findOrFail($id);
        $sourceBranchId = $request->input('source_branch_id', 1);

        if ($targetBranch->id == $sourceBranchId) {
            return response()->json(['message' => 'Cabang sumber dan cabang tujuan tidak boleh sama.'], 422);
        }

        DB::beginTransaction();
        try {
            // 1. Copy Categories
            $sourceCategories = Category::where('branch_id', $sourceBranchId)->get();
            $categoryMap = []; // old_id => new_id

            foreach ($sourceCategories as $cat) {
                $newCat = Category::firstOrCreate(
                    [
                        'branch_id' => $targetBranch->id,
                        'name' => $cat->name,
                    ],
                    [
                        'slug' => $cat->slug . '-b' . $targetBranch->id,
                        'description' => $cat->description,
                        'image' => $cat->image,
                        'is_active' => $cat->is_active,
                    ]
                );
                $categoryMap[$cat->id] = $newCat->id;
            }

            // 2. Copy Raw Materials
            $sourceMaterials = RawMaterial::where('branch_id', $sourceBranchId)->get();
            $materialMap = []; // old_id => new_id

            foreach ($sourceMaterials as $mat) {
                $newMat = RawMaterial::firstOrCreate(
                    [
                        'branch_id' => $targetBranch->id,
                        'name' => $mat->name,
                    ],
                    [
                        'brand' => $mat->brand,
                        'stock' => 0, // Fresh stock
                        'unit' => $mat->unit,
                        'unit_large' => $mat->unit_large,
                        'unit_small' => $mat->unit_small,
                        'conversion_value' => $mat->conversion_value,
                        'price_per_large_unit' => $mat->price_per_large_unit,
                        'price_per_small_unit' => $mat->price_per_small_unit,
                        'min_stock' => $mat->min_stock,
                        'is_active' => $mat->is_active,
                        'image' => $mat->image,
                    ]
                );
                $materialMap[$mat->id] = $newMat->id;
            }

            // 3. Copy Products
            $sourceProducts = Product::where('branch_id', $sourceBranchId)->with('ingredients')->get();
            $copiedProductsCount = 0;

            foreach ($sourceProducts as $prod) {
                $newCategoryId = isset($categoryMap[$prod->category_id]) ? $categoryMap[$prod->category_id] : null;

                $newProduct = Product::create([
                    'branch_id' => $targetBranch->id,
                    'category_id' => $newCategoryId,
                    'name' => $prod->name,
                    'slug' => $prod->slug ? ($prod->slug . '-b' . $targetBranch->id) : null,
                    'description' => $prod->description,
                    'sku' => $prod->sku ? ($prod->sku . '-b' . $targetBranch->id) : null,
                    'price' => $prod->price,
                    'hpp' => $prod->hpp,
                    'stock' => 0, // Reset to 0 for new branch
                    'image' => $prod->image,
                    'is_active' => $prod->is_active,
                ]);

                // Copy ingredients
                foreach ($prod->ingredients as $ing) {
                    if (isset($materialMap[$ing->raw_material_id])) {
                        ProductIngredient::create([
                            'product_id' => $newProduct->id,
                            'raw_material_id' => $materialMap[$ing->raw_material_id],
                            'quantity_used' => $ing->quantity_used,
                        ]);
                    }
                }

                $copiedProductsCount++;
            }

            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => "Berhasil menyalin {$copiedProductsCount} menu ke {$targetBranch->name}.",
                'copied_products' => $copiedProductsCount,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menyalin katalog: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/branches/{id}/summary
     * Return counts of active records in the branch.
     */
    public function summary(Request $request, int $id)
    {
        $branch = Branch::findOrFail($id);
        return response()->json([
            'status' => 'success',
            'data' => [
                'branch' => $branch,
                'summary' => $branch->getDataSummary(),
                'has_data' => $branch->hasData(),
            ],
        ]);
    }

    /**
     * DELETE /api/branches/{id}
     * Safely delete branch and its operational data after password confirmation (Owner only).
     */
    public function destroy(Request $request, int $id)
    {
        if (!$request->user()->isOwner()) {
            return response()->json(['message' => 'Hanya Owner yang dapat menghapus cabang.'], 403);
        }

        $request->validate([
            'password' => 'required|string',
        ]);

        $branch = Branch::findOrFail($id);

        try {
            $branchName = $branch->name;
            $branch->safeDeleteWithPassword($request->password, $request->user());

            return response()->json([
                'status' => 'success',
                'message' => "Cabang '{$branchName}' beserta seluruh datanya berhasil dihapus permanen.",
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Password salah! Konfirmasi penghapusan gagal.',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 400);
        }
    }
}
