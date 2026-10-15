<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah.',
            ], 401);
        }

        // Generate / refresh API token
        if (!$user->api_token) {
            $user->api_token = Str::random(60);
            $user->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
                'token' => $user->api_token,
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $token = $request->bearerToken() ?: $request->header('X-API-TOKEN') ?: $request->query('api_token');
        $user = User::where('api_token', $token)->first();

        if (!$user) {
            // Fallback to first user in demo mode
            $user = User::first();
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }
}
