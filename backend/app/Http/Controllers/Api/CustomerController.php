<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\SecurityAuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Customer::query();

        if ($request->has('tier') && $request->tier !== 'Semua') {
            $query->where('tier', $request->tier);
        }

        if ($request->has('search') && !empty($request->search)) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('name', 'like', "%{$s}%")
                    ->orWhere('email', 'like', "%{$s}%")
                    ->orWhere('phone', 'like', "%{$s}%")
                    ->orWhere('city', 'like', "%{$s}%");
            });
        }

        $customers = $query->orderBy('id', 'desc')->get();

        $totalSpentSum = Customer::sum('total_spent');
        $vipCount = Customer::where('tier', 'VIP')->count();
        $totalOrdersSum = Customer::sum('total_orders');
        $avgOrders = Customer::count() > 0 ? round($totalOrdersSum / Customer::count(), 1) : 0;

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'total_customers' => Customer::count(),
                    'vip_customers' => $vipCount,
                    'total_spent' => (float) $totalSpentSum,
                    'avg_orders' => $avgOrders,
                ],
                'customers' => $customers,
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string',
            'tier' => 'nullable|string',
        ]);

        $customer = Customer::create([
            'name' => $request->name,
            'email' => $request->email ?? 'pelanggan@mail.com',
            'phone' => $request->phone,
            'tier' => $request->tier ?? 'Regular',
            'city' => $request->city ?? 'Jakarta',
            'total_orders' => 0,
            'total_spent' => 0,
            'last_active' => 'Baru saja',
            'status' => 'Aktif',
            'notes' => $request->notes ?? '',
        ]);

        SecurityAuditLog::create([
            'user' => 'Admin User',
            'role' => 'Superadmin',
            'action' => "Tambah Pelanggan Baru: {$customer->name} (Tier: {$customer->tier})",
            'target' => 'CRM Pelanggan',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pelanggan berhasil ditambahkan.',
            'data' => $customer,
        ], 201);
    }

    public function show(int $id): JsonResponse
    {
        $customer = Customer::with('transactions.items')->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $customer,
        ]);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);
        $customer->update($request->only([
            'name',
            'email',
            'phone',
            'tier',
            'city',
            'status',
            'notes',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Data pelanggan berhasil diperbarui.',
            'data' => $customer,
        ]);
    }

    public function destroy(int $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);
        $name = $customer->name;
        $customer->delete();

        return response()->json([
            'success' => true,
            'message' => "Pelanggan {$name} berhasil dihapus.",
        ]);
    }
}
