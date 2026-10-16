<?php

namespace App\Http\Middleware;

use App\Models\User;
use App\Services\BillingService;
use Closure;
use Illuminate\Http\Request;

class ApiTokenAuth
{
    public function handle(Request $request, Closure $next)
    {
        $token = $request->bearerToken() ?: $request->header('X-API-TOKEN');
        $user = is_string($token) && $token !== '' ? User::where('api_token', $token)->first() : null;
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Silakan login dengan token yang valid.'], 401);
        }
        $request->setUserResolver(fn () => $user);
        if (!$request->is('api/auth/*', 'api/billing/*') && !app(BillingService::class)->seatAllowed($user)) {
            return response()->json(['success' => false, 'message' => 'Akun ini di luar batas pengguna paket. Hubungi pemilik toko untuk peningkatan paket.'], 403);
        }
        return $next($request);
    }
}
