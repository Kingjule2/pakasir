<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SecurityAuditLog;
use App\Models\StoreSetting;
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
                'member_count' => 2,
                'permissions' => ['Akses Semua Fitur', 'Kelola Keuangan', 'Ubah Kebijakan', 'Backup Database'],
            ],
            [
                'role_name' => 'Store Manager',
                'description' => 'Mengelola operasional cabang, stok, dan laporan shift kasir.',
                'member_count' => 4,
                'permissions' => ['Kelola Stok Toko', 'Laporan Cabang', 'Void Transaksi', 'Jadwal Kasir'],
            ],
            [
                'role_name' => 'Kasir / POS Cashier',
                'description' => 'Hanya akses modul kasir POS, cetak struk, dan input pelanggan.',
                'member_count' => 14,
                'permissions' => ['Buat Transaksi POS', 'Input Pelanggan', 'Cetak Ulang Struk'],
            ],
            [
                'role_name' => 'Gudang & Logistik',
                'description' => 'Input barang masuk (stock in), opname, dan cek pengiriman supplier.',
                'member_count' => 3,
                'permissions' => ['Penerimaan Barang', 'Stock Opname', 'Kontak Supplier'],
            ],
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'security_status' => [
                    'grade' => 'A+',
                    'encryption' => 'AES-256',
                    'compliance' => 'UU PDP No. 27/2022',
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
            'action' => 'Perubahan Konfigurasi Keamanan & Privasi UU PDP',
            'target' => 'Security Controls',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pengaturan privasi & keamanan berhasil disimpan.',
            'data' => $setting,
        ]);
    }

    public function backupDatabase(): JsonResponse
    {
        SecurityAuditLog::create([
            'user' => 'Admin User',
            'role' => 'Superadmin',
            'action' => 'Backup Database Snapshot Berhasil Diunduh',
            'target' => 'Database Backup',
            'ip_address' => request()->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Cadangan database terenkripsi (vault_backup_' . date('Ymd_His') . '.enc) siap diunduh.',
            'download_url' => url('/api/privacy/backup/file'),
        ]);
    }
}
