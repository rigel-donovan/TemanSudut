<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index()
    {
        // Only owner can see users
        if (auth()->user()->isCashier()) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }
        return response()->json(User::select('id', 'name', 'email', 'role', 'created_at')->get());
    }

    public function store(Request $request)
    {
        if (auth()->user()->isCashier()) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'role' => 'required|in:owner,cashier',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'],
        ]);

        ActivityLog::log('user_created', 'User "' . $user->name . '" (' . $user->role . ') ditambahkan oleh ' . auth()->user()->name, [
            'new_user_id' => $user->id,
            'role' => $user->role,
        ]);

        return response()->json($user, 201);
    }

    public function update(Request $request, string $id)
    {
        if (auth()->user()->isCashier()) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $user = User::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $id,
            'password' => 'sometimes|string|min:6',
            'role' => 'sometimes|in:owner,cashier',
        ]);

        if (isset($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        }

        $oldRole = $user->role;
        $user->update($validated);

        ActivityLog::log('user_updated', 'User "' . $user->name . '" diubah oleh ' . auth()->user()->name, [
            'target_user_id' => $user->id,
            'old_role' => $oldRole,
            'new_role' => $user->role,
        ]);

        return response()->json($user);
    }

    public function destroy(string $id)
    {
        if (auth()->user()->isCashier()) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        // Prevent self-deletion
        if (auth()->id() == $id) {
            return response()->json(['message' => 'Tidak bisa menghapus akun sendiri.'], 422);
        }

        $user = User::findOrFail($id);
        $userName = $user->name;
        $user->delete();

        ActivityLog::log('user_deleted', 'User "' . $userName . '" dihapus oleh ' . auth()->user()->name, [
            'deleted_user_id' => $id,
        ]);

        return response()->json(['message' => 'User berhasil dihapus.']);
    }
}
