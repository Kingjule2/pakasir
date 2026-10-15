<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SecurityAuditLog;
use App\Models\StoreSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    public function index(): JsonResponse
    {
        $setting = StoreSetting::first();

        if (!$setting) {
            $setting = StoreSetting::create([]);
        }

        return response()->json([
            'success' => true,
            'data' => $setting,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $setting = StoreSetting::first();

        if (!$setting) {
            $setting = StoreSetting::create([]);
        }

        $setting->update($request->only([
            'store_name',
            'store_tagline',
            'email',
            'phone',
            'address',
            'currency_symbol',
            'currency_code',
            'tax_rate',
            'tax_enabled',
            'service_fee_rate',
            'service_fee_enabled',
            'printer_name',
            'paper_width',
            'auto_print_receipt',
            'sound_alerts',
            'low_stock_threshold',
            'low_stock_notification',
            'daily_report_email',
            'two_factor_auth_enabled',
            'biometric_login_enabled',
            'customer_data_anonymized',
            'language',
        ]));

        SecurityAuditLog::create([
            'user' => 'Admin User',
            'role' => 'Superadmin',
            'action' => 'Pembaruan Konfigurasi Sistem & Pengaturan Toko',
            'target' => 'System Settings',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pengaturan toko berhasil diperbarui.',
            'data' => $setting,
        ]);
    }
}
