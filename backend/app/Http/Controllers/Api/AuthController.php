<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($request->only('email', 'password'))) {
            $user = Auth::user();
            $token = $user->createToken('auth_token')->plainTextToken;

            $branches = [];
            try {
                if (\Illuminate\Support\Facades\Schema::hasTable('branches')) {
                    $branches = $user->isOwner()
                        ? \App\Models\Branch::where('is_active', true)->get()
                        : $user->branches()->where('is_active', true)->get();

                    if ($branches->isEmpty()) {
                        $branches = \App\Models\Branch::where('id', 1)->get();
                    }
                }
            } catch (\Throwable $e) {
                // Table might not exist or migration not run
            }

            if (empty($branches) || (is_object($branches) && $branches->isEmpty())) {
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
                'message' => 'Login successful',
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => $user,
                'branches' => $branches,
            ]);
        }

        return response()->json(['message' => 'Invalid login credentials'], 401);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out successfully']);
    }

    public function me(Request $request) 
    {
        $user = $request->user();
        $branches = [];
        try {
            if (\Illuminate\Support\Facades\Schema::hasTable('branches')) {
                $branches = $user->isOwner()
                    ? \App\Models\Branch::where('is_active', true)->get()
                    : $user->branches()->where('is_active', true)->get();

                if ($branches->isEmpty()) {
                    $branches = \App\Models\Branch::where('id', 1)->get();
                }
            }
        } catch (\Throwable $e) {
            // Table might not exist or migration not run
        }

        if (empty($branches) || (is_object($branches) && $branches->isEmpty())) {
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

        $userData = $user->toArray();
        $userData['branches'] = $branches;

        return response()->json($userData);
    }

    /** PUT /profile — update name & email */
    public function updateProfile(Request $request)
    {
        $validated = $request->validate([
            'name'  => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email,' . $request->user()->id,
        ]);

        $request->user()->update($validated);

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'user'    => $request->user()->fresh(),
        ]);
    }

    /** PUT /profile/password — change password */
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password'     => 'required|string|min:6|confirmed',
        ]);

        if (!Hash::check($request->current_password, $request->user()->password)) {
            return response()->json(['message' => 'Password lama tidak sesuai.'], 422);
        }

        $request->user()->update([
            'password' => Hash::make($request->new_password),
        ]);

        return response()->json(['message' => 'Password berhasil diperbarui.']);
    }
}
