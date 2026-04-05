<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RolePermission;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class PermissionController extends Controller
{
    public function index()
    {
        $result = Cache::remember('permissions_matrix', 3600, function () {
            $matrix = RolePermission::allAsMatrix();
            $result = [];
            foreach (RolePermissionSeeder::$features as $key => $config) {
                $result[$key] = [
                    'label' => $config['label'],
                    'owner' => $matrix[$key]['owner'] ?? $config['owner'],
                    'cashier' => $matrix[$key]['cashier'] ?? $config['cashier'],
                ];
            }
            return $result;
        });

        return response()->json($result);
    }

    public function update(Request $request)
    {
        $permissions = $request->input('permissions', []);

        foreach ($permissions as $feature => $roles) {
            foreach (['owner', 'cashier'] as $role) {
                if (isset($roles[$role])) {
                    RolePermission::updateOrCreate(
                    ['feature' => $feature, 'role' => $role],
                    ['enabled' => (bool)$roles[$role]]
                    );
                }
            }
        }

        Cache::forget('permissions_matrix');

        return response()->json(['message' => 'Permissions updated successfully.']);
    }
}
