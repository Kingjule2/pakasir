<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SecurityAuditLog;
use App\Models\StoreSetting;
use App\Models\Customer;
use App\Models\Product;
use App\Models\StoreOutlet;
use App\Models\Transaction;
use App\Models\User;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PrivacyController extends Controller
{
    public function index(): JsonResponse
    {
        $setting = StoreSetting::first();

        $roles = [
            [
                'role_name' => 'Owner / Super Admin',
                'description' => 'Akses penuh seluruh sistem, finansial, dan audit log.',
                'member_count' => User::whereIn('role', ['owner', 'superadmin'])->count(),
                'permissions' => ['Akses Semua Fitur', 'Kelola Keuangan', 'Ubah Kebijakan', 'Backup Database'],
            ],
            [
                'role_name' => 'Store Manager',
                'description' => 'Mengelola operasional cabang, stok, dan laporan shift kasir.',
                'member_count' => User::where('role', 'manager')->count(),
                'permissions' => ['Kelola Stok Toko', 'Laporan Cabang', 'Void Transaksi', 'Jadwal Kasir'],
            ],
            [
                'role_name' => 'Kasir / POS Cashier',
                'description' => 'Hanya akses modul kasir POS, cetak struk, dan input pelanggan.',
                'member_count' => User::where('role', 'cashier')->count(),
                'permissions' => ['Buat Transaksi POS', 'Input Pelanggan', 'Cetak Ulang Struk'],
            ],
            [
                'role_name' => 'Gudang & Logistik',
                'description' => 'Input barang masuk (stock in), opname, dan cek pengiriman supplier.',
                'member_count' => User::where('role', 'warehouse')->count(),
                'permissions' => ['Penerimaan Barang', 'Stock Opname', 'Kontak Supplier'],
            ],
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'security_status' => [
                    'grade' => null,
                    'encryption' => null,
                    'compliance' => 'Belum diaudit',
                    'notice' => 'Pilihan ini menyimpan preferensi; bukan bukti MFA, biometrik, atau anonimisasi sudah diterapkan.',
                    'two_factor_auth_enabled' => $setting ? $setting->two_factor_auth_enabled : true,
                    'biometric_login_enabled' => $setting ? $setting->biometric_login_enabled : true,
                    'customer_data_anonymized' => $setting ? $setting->customer_data_anonymized : false,
                ],
                'user_roles' => $roles,
            ],
        ]);
    }

    public function auditLogs(Request $request): JsonResponse
    {
        $logs = SecurityAuditLog::orderBy('id', 'desc')->take(50)->get();

        return response()->json([
            'success' => true,
            'data' => $logs,
        ]);
    }

    public function toggleSecurity(Request $request): JsonResponse
    {
        $request->validate([
            'two_factor_auth_enabled' => 'sometimes|boolean',
            'biometric_login_enabled' => 'sometimes|boolean',
            'customer_data_anonymized' => 'sometimes|boolean',
        ]);
        $setting = StoreSetting::first();

        if ($request->has('two_factor_auth_enabled')) {
            $setting->two_factor_auth_enabled = (bool) $request->two_factor_auth_enabled;
        }

        if ($request->has('biometric_login_enabled')) {
            $setting->biometric_login_enabled = (bool) $request->biometric_login_enabled;
        }

        if ($request->has('customer_data_anonymized')) {
            $setting->customer_data_anonymized = (bool) $request->customer_data_anonymized;
        }

        $setting->save();

        SecurityAuditLog::create([
            'user' => 'Admin User',
            'role' => 'Superadmin',
            'action' => 'Perubahan Preferensi Keamanan & Privasi',
            'target' => 'Security Controls',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Preferensi disimpan; kontrol keamanan memerlukan penerapan dan audit terpisah.',
            'data' => $setting,
        ]);
    }

    public function backupDatabase(): StreamedResponse
    {
        SecurityAuditLog::create([
            'user' => request()->user()?->name ?? 'Admin',
            'role' => request()->user()?->role ?? 'admin',
            'action' => 'Ekspor data operasional JSON diminta',
            'target' => 'Data Export',
            'ip_address' => request()->ip(),
            'status' => 'Sukses',
        ]);

        return response()->streamDownload(function () {
            // Export operational records only: never API keys, tokens, or password hashes.
            echo json_encode([
                'format' => 'pakasir-operational-export',
                'exported_at' => now()->toIso8601String(),
                'notice' => 'Ekspor JSON tidak terenkripsi, bukan backup SQL. Simpan secara aman.',
                'products' => Product::all(),
                'customers' => Customer::all(),
                'outlets' => StoreOutlet::all(),
                'transactions' => Transaction::with('items')->get(),
                'settings' => StoreSetting::all(),
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT | JSON_THROW_ON_ERROR);
        }, 'pakasir-data-' . now()->format('Ymd-His') . '.json', ['Content-Type' => 'application/json']);
    }
}
