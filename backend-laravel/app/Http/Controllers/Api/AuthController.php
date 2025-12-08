<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Models\User;
use App\Models\ActivityHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * Handle user login.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('username', $request->username)->first();

        // Check if account is blocked
        if ($user && $user->isBlocked()) {
            return response()->json([
                'status' => 403,
                'message' => 'Account is temporarily blocked due to multiple failed login attempts. Please try again later.',
                'timestamp' => now()->toIso8601String(),
            ], 403);
        }

        // Verify password
        if (!$user || !Hash::check($request->password, $user->password)) {
            if ($user) {
                $user->incrementLoginAttempts($request->ip());
            }

            return response()->json([
                'status' => 401,
                'message' => 'Invalid credentials',
                'timestamp' => now()->toIso8601String(),
            ], 401);
        }

        // Reset login attempts on successful login
        $user->resetLoginAttempts();

        // Update last login and FCM token
        $user->update([
            'terakhir_login' => now(),
            'fcm_token' => $request->fcm_token,
        ]);

        // Create token
        $token = $user->createToken('auth-token')->plainTextToken;

        // Log activity
        ActivityHistory::log(
            userId: $user->id_user,
            action: 'login',
            description: 'User logged in successfully',
            ipAddress: $request->ip(),
            userAgent: $request->userAgent()
        );

        return response()->json([
            'status' => 200,
            'message' => 'Login successful',
            'data' => [
                'token' => $token,
                'user' => [
                    'id_user' => $user->id_user,
                    'username' => $user->username,
                    'nama_lengkap' => $user->nama_lengkap,
                    'email' => $user->email,
                    'jabatan' => $user->jabatan,
                    'role' => $user->role,
                    'level' => $user->level,
                    'instansi' => $user->instansi,
                    'kode_user' => $user->kode_user,
                ],
            ],
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Handle user logout.
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();

        // Log activity
        ActivityHistory::log(
            userId: $user->id_user,
            action: 'logout',
            description: 'User logged out',
            ipAddress: $request->ip(),
            userAgent: $request->userAgent()
        );

        // Revoke current token
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => 200,
            'message' => 'Logout successful',
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Get current authenticated user basic information.
     */
    public function user(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'status' => 200,
            'data' => [
                'id_user' => $user->id_user,
                'username' => $user->username,
                'nama_lengkap' => $user->nama_lengkap,
                'role' => $user->role,
                'level' => $user->level,
                'kode_user' => $user->kode_user,
            ],
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    /**
     * Get complete user profile.
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'status' => 200,
            'data' => [
                'id_user' => $user->id_user,
                'username' => $user->username,
                'nama_lengkap' => $user->nama_lengkap,
                'email' => $user->email,
                'telp' => $user->telp,
                'alamat' => $user->alamat,
                'jabatan' => $user->jabatan,
                'role' => $user->role,
                'instansi' => $user->instansi,
                'level' => $user->level,
                'level_pimpinan' => $user->level_pimpinan,
                'level_tu' => $user->level_tu,
                'level_admin' => $user->level_admin,
                'level_manajemen' => $user->level_manajemen,
                'kode_user' => $user->kode_user,
                'status' => $user->status,
                'terakhir_login' => $user->terakhir_login?->toIso8601String(),
                'tgl_daftar' => $user->tgl_daftar?->toIso8601String(),
            ],
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
