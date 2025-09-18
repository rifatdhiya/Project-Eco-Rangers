<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    // POST /api/register
    public function register(Request $request)
    {
        $data = $request->validate([
            'username' => ['required','alpha_dash','min:3','max:30','unique:users,username'],
            'email'    => ['required','email','unique:users,email'],
            'password' => ['required', Password::min(8)],
        ]);

        // password otomatis di-hash (lihat User::$casts)
        $user = User::create([
            'username' => $data['username'],
            'name'     => $data['username'], // <— tambahkan baris ini
            'email'    => $data['email'],
            'password' => $data['password'], // di-hash otomatis oleh casts
        ]);


        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'message' => 'Registered',
            'data'    => ['user' => $user],
            'token'   => $token,
        ], 201);
    }

    // POST /api/login
    public function login(Request $request)
    {
        $data = $request->validate([
            'email'    => ['required','email'],
            'password' => ['required'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'message' => 'Logged in',
            'data'    => ['user' => $user],
            'token'   => $token,
        ], 200);
    }

    // GET /api/me (butuh token)
    public function me(Request $request)
    {
        return response()->json($request->user());
    }

    // POST /api/logout (butuh token)
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out']);
    }
}
