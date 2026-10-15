<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SecurityAuditLog;
use App\Models\StoreOutlet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StoreOutletController extends Controller
{
    public function index(): JsonResponse
    {
        $outlets = StoreOutlet::all();
        $openCount = $outlets->where('is_open', true)->count();
        $totalTerminals = $outlets->sum('terminals_count');
        $totalDailySales = $outlets->where('is_open', true)->sum('daily_sales');
        $totalStaff = $outlets->sum('staff_count');

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'open_outlets' => $openCount,
                    'total_outlets' => $outlets->count(),
                    'total_terminals' => $totalTerminals,
                    'total_daily_sales' => (float) $totalDailySales,
                    'total_staff' => $totalStaff,
                ],
                'outlets' => $outlets,
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|unique:store_outlets,code',
            'city' => 'required|string',
            'address' => 'required|string',
            'manager' => 'required|string',
            'phone' => 'required|string',
        ]);

        $outlet = StoreOutlet::create([
            'name' => $request->name,
            'code' => $request->code,
            'city' => $request->city,
            'address' => $request->address,
            'manager' => $request->manager,
            'phone' => $request->phone,
            'operating_hours' => $request->operating_hours ?? '09:00 - 22:00 WIB',
            'is_open' => true,
            'terminals_count' => $request->terminals_count ?? 2,
            'daily_sales' => 0,
            'monthly_sales' => 0,
            'staff_count' => $request->staff_count ?? 4,
        ]);

        SecurityAuditLog::create([
            'user' => 'Admin User',
            'role' => 'Superadmin',
            'action' => "Buka Cabang Baru: {$outlet->name} ({$outlet->code})",
            'target' => 'Multi-Outlet',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Cabang toko berhasil ditambahkan.',
            'data' => $outlet,
        ], 201);
    }

    public function toggleStatus(Request $request, int $id): JsonResponse
    {
        $outlet = StoreOutlet::findOrFail($id);
        $outlet->is_open = !$outlet->is_open;
        $outlet->save();

        SecurityAuditLog::create([
            'user' => 'Admin User',
            'role' => 'Superadmin',
            'action' => "Ubah Status Toko {$outlet->name} menjadi: " . ($outlet->is_open ? 'BUKA' : 'TUTUP'),
            'target' => 'Multi-Outlet',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => "Status {$outlet->name} berhasil diubah menjadi: " . ($outlet->is_open ? 'BUKA' : 'TUTUP'),
            'data' => $outlet,
        ]);
    }
}
