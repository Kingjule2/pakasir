<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SalesAnalytic;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $period = $request->query('period', 'Bulan Ini');

        // Financial Overview
        $totalRevenue = 284500000.0;
        $totalHpp = 168000000.0;
        $grossProfit = $totalRevenue - $totalHpp;
        $operationalCost = 38500000.0;
        $netProfit = $grossProfit - $operationalCost;
        $cashInHand = 94200000.0;

        // P&L Detailed Items
        $pnl = [
            'gross_revenue' => $totalRevenue,
            'cogs_hpp' => -$totalHpp,
            'gross_profit' => $grossProfit,
            'expenses' => [
                ['name' => 'Beban Gaji Karyawan', 'amount' => -22000000.0],
                ['name' => 'Sewa Tempat & Utilitas', 'amount' => -11500000.0],
                ['name' => 'Beban Pemasaran & Promo', 'amount' => -5000000.0],
            ],
            'total_expenses' => -$operationalCost,
            'net_profit' => $netProfit,
            'profit_margin' => round(($netProfit / $totalRevenue) * 100, 1),
        ];

        // Fund Allocation
        $allocations = [
            ['label' => 'Anggaran Kulakan Stok', 'amount' => 50000000.0, 'percentage' => 0.53],
            ['label' => 'Operasional Toko & Shift', 'amount' => 25000000.0, 'percentage' => 0.27],
            ['label' => 'Dana Cadangan Darurat', 'amount' => 15000000.0, 'percentage' => 0.16],
            ['label' => 'Prive / Bagi Hasil', 'amount' => 4200000.0, 'percentage' => 0.04],
        ];

        // Payment Methods breakdown
        $paymentMethods = [
            ['method' => 'QRIS (GoPay, OVO, ShopeePay, Dana)', 'share' => '45%', 'value' => 0.45],
            ['method' => 'Mesin EDC (BCA, Mandiri, BRI)', 'share' => '25%', 'value' => 0.25],
            ['method' => 'Tunai / Cash', 'share' => '18%', 'value' => 0.18],
            ['method' => 'Transfer Virtual Account', 'share' => '12%', 'value' => 0.12],
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'summary' => [
                    'total_revenue' => $totalRevenue,
                    'total_hpp' => $totalHpp,
                    'gross_profit' => $grossProfit,
                    'operational_cost' => $operationalCost,
                    'net_profit' => $netProfit,
                    'cash_in_hand' => $cashInHand,
                ],
                'profit_and_loss' => $pnl,
                'fund_allocations' => $allocations,
                'payment_methods' => $paymentMethods,
            ],
        ]);
    }

    public function export(Request $request): JsonResponse
    {
        $type = $request->query('type', 'csv'); // csv or pdf
        $period = $request->query('period', 'Bulan Ini');

        return response()->json([
            'success' => true,
            'message' => "Laporan finansial ({$period}) berhasil diexport ke format " . strtoupper($type),
            'download_url' => url("/api/reports/download?token=vault-" . time()),
        ]);
    }
}
