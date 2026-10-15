<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Product;
use App\Models\SalesAnalytic;
use App\Models\SecurityAuditLog;
use App\Models\StoreOutlet;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function index(): JsonResponse
    {
        $products = Product::all();
        $criticalCount = $products->filter(function ($p) {
            return $p->stock_in < ($p->total_qty * 0.3) || $p->is_out_of_stock;
        })->count();

        $outlets = StoreOutlet::all();
        $openOutletsCount = $outlets->where('is_open', true)->count();
        $totalDailyOutletSales = $outlets->where('is_open', true)->sum('daily_sales');

        $totalCustomers = Customer::count();
        $vipCustomers = Customer::where('tier', 'VIP')->count();

        // 7 days sales velocity
        $analytics = SalesAnalytic::orderBy('analysis_date', 'asc')->take(7)->get();
        $chartData = $analytics->map(function ($item) {
            return [
                'date' => $item->analysis_date->format('Y-m-d'),
                'day' => $item->analysis_date->format('D'),
                'revenue' => (float) $item->total_revenue,
                'profit' => (float) $item->total_profit,
                'quantity' => (int) $item->total_quantity,
            ];
        });

        // Top 4 selling products
        $topProducts = Product::take(4)->get()->map(function ($p) {
            return [
                'id' => $p->id,
                'name' => $p->name,
                'sku' => $p->sku,
                'category' => $p->category,
                'price' => (float) $p->price,
                'stock_in' => (int) $p->stock_in,
                'tag' => $p->tag,
                'is_low_stock' => $p->stock_in < 30,
            ];
        });

        // Recent live activities
        $recentTransactions = Transaction::with(['customer', 'outlet'])
            ->orderBy('id', 'desc')
            ->take(3)
            ->get()
            ->map(function ($t) {
                return [
                    'id' => $t->id,
                    'title' => "Pesanan #{$t->invoice_number} Selesai",
                    'subtitle' => ($t->outlet ? $t->outlet->name : 'SCBD') . " • Pembayaran {$t->payment_method} Rp " . number_format($t->total_amount, 0, ',', '.'),
                    'time' => $t->created_at->diffForHumans(),
                    'type' => 'transaction',
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'system_status' => [
                    'status' => 'LIVE_ONLINE',
                    'open_outlets' => $openOutletsCount,
                    'total_outlets' => $outlets->count(),
                    'critical_stock_count' => $criticalCount,
                ],
                'kpi' => [
                    'today_sales' => (float) $totalDailyOutletSales,
                    'monthly_turnover' => 284500000.0,
                    'total_customers' => $totalCustomers,
                    'vip_customers' => $vipCustomers,
                    'low_stock_alerts' => $criticalCount,
                ],
                'sales_velocity_chart' => $chartData,
                'outlets_leaderboard' => $outlets,
                'top_products' => $topProducts,
                'recent_activities' => $recentTransactions,
            ],
        ]);
    }
}
