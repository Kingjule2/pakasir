<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Product;
use App\Models\StoreOutlet;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function index(): JsonResponse
    {
        $products = Product::whereNull('deleted_at')->get();
        $outOfStockCount = $products->filter(fn ($p) => $p->stock_in <= 0 || $p->is_out_of_stock)->count();
        $lowStockCount = $products->filter(fn ($p) => $p->stock_in > 0 && !$p->is_out_of_stock && $p->stock_in < max(30, $p->total_qty * 0.3))->count();
        $inStockCount = max(0, $products->count() - $outOfStockCount - $lowStockCount);
        $criticalCount = $outOfStockCount + $lowStockCount;
        $stockAlerts = $products->filter(fn ($p) => $p->stock_in < max(30, $p->total_qty * 0.3) || $p->is_out_of_stock)
            ->sortBy('stock_in')
            ->take(3)
            ->values()
            ->map(fn ($p) => [
                'id' => $p->id,
                'name' => $p->name,
                'sku' => $p->sku,
                'category' => $p->category,
                'stock_in' => (int) $p->stock_in,
                'total_qty' => (int) $p->total_qty,
                'is_out_of_stock' => (bool) ($p->stock_in <= 0 || $p->is_out_of_stock),
            ]);
        $outlets = StoreOutlet::all();
        $openOutletsCount = $outlets->where('is_open', true)->count();
        $paid = Transaction::where('payment_status', 'paid');
        $todaySales = (clone $paid)->whereBetween('transaction_date', [now()->startOfDay(), now()])->sum('total_amount');
        $monthlyTurnover = (clone $paid)->whereBetween('transaction_date', [now()->startOfMonth(), now()])
            ->selectRaw('COALESCE(SUM(subtotal - discount + service_fee), 0) as revenue')->value('revenue');

        $totalCustomers = Customer::count();
        $vipCustomers = Customer::where('tier', 'VIP')->count();

        $recent = (clone $paid)->with('items')
            ->whereBetween('transaction_date', [now()->subDays(6)->startOfDay(), now()])->get();
        $byDay = $recent->groupBy(fn ($row) => $row->transaction_date->format('Y-m-d'));
        $chartData = collect(range(6, 0))->map(function ($days) use ($byDay) {
            $date = now()->subDays($days);
            $rows = $byDay->get($date->format('Y-m-d'), collect());
            $revenue = $rows->sum(fn ($row) => $row->subtotal - $row->discount + $row->service_fee);
            $hpp = $rows->sum(fn ($row) => $row->items->sum(fn ($item) => $item->cost_price * $item->quantity));
            return [
                'date' => $date->format('Y-m-d'), 'day' => $date->format('D'),
                'revenue' => (float) $revenue, 'profit' => (float) ($revenue - $hpp),
                'quantity' => $rows->sum(fn ($row) => $row->items->sum('quantity')),
            ];
        });
        $sold = $recent->flatMap->items->groupBy('product_id')->map(fn ($items) => $items->sum('quantity'));
        $topProducts = $products->filter(fn ($product) => $sold->get($product->id, 0) > 0)
            ->sortByDesc(fn ($product) => $sold->get($product->id, 0))->take(4)->values()->map(fn ($product) => [
                'id' => $product->id, 'name' => $product->name, 'sku' => $product->sku,
                'category' => $product->category, 'price' => (float) $product->price,
                'stock_in' => (int) $product->stock_in, 'tag' => $product->tag,
                'is_low_stock' => $product->stock_in < 30, 'quantity_sold' => $sold->get($product->id),
            ]);

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
                'critical_stock' => $criticalCount,
                'open_outlets' => $openOutletsCount,
                'total_revenue' => (float) $monthlyTurnover,
                'total_products' => $products->count(),
                'chart_velocity' => $chartData,
                'stock_availability' => [
                    'in_stock' => $inStockCount,
                    'low_stock' => $lowStockCount,
                    'out_of_stock' => $outOfStockCount,
                    'total' => $products->count(),
                ],
                'stock_alerts' => $stockAlerts,
                'system_status' => [
                    'status' => 'LIVE_ONLINE',
                    'open_outlets' => $openOutletsCount,
                    'total_outlets' => $outlets->count(),
                    'critical_stock_count' => $criticalCount,
                ],
                'kpi' => [
                    'today_sales' => (float) $todaySales,
                    'monthly_turnover' => (float) $monthlyTurnover,
                    'total_customers' => $totalCustomers,
                    'vip_customers' => $vipCustomers,
                    'low_stock_alerts' => $criticalCount,
                    'total_products' => $products->count(),
                ],
                'sales_velocity_chart' => $chartData,
                'outlets_leaderboard' => $outlets,
                'top_products' => $topProducts,
                'recent_activities' => $recentTransactions,
            ],
        ]);
    }
}
