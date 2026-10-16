<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    private function transactions(Request $request)
    {
        $request->validate(['period' => ['nullable', Rule::in(['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'])]]);
        $start = match ($request->query('period', 'Bulan Ini')) {
            'Hari Ini' => now()->startOfDay(),
            'Minggu Ini' => now()->startOfWeek(),
            'Tahun Ini' => now()->startOfYear(),
            default => now()->startOfMonth(),
        };

        return Transaction::where('payment_status', 'paid')
            ->whereBetween('transaction_date', [$start, now()]);
    }

    public function index(Request $request): JsonResponse
    {
        $transactions = $this->transactions($request)->with('items')->get();
        // Tax collected is not revenue; item costs are historical checkout snapshots.
        $revenue = (float) $transactions->sum(fn ($row) => $row->subtotal - $row->discount + $row->service_fee);
        $hpp = (float) $transactions->sum(fn ($row) => $row->items->sum(fn ($item) => $item->cost_price * $item->quantity));
        $grossProfit = $revenue - $hpp;
        $payments = (float) $transactions->sum('total_amount');
        $methods = $transactions->groupBy('payment_method')->map(function ($rows, $method) use ($payments) {
            $amount = (float) $rows->sum('total_amount');
            $share = $payments > 0 ? $amount / $payments : 0;
            return ['method' => $method, 'amount' => $amount, 'value' => $share, 'share' => round($share * 100, 1) . '%'];
        })->values();

        return response()->json(['success' => true, 'data' => [
            'period' => $request->query('period', 'Bulan Ini'),
            'source' => 'Transaksi POS berstatus paid; pajak tidak termasuk pendapatan.',
            'note' => 'Biaya operasional, saldo kas, dan laba bersih belum dicatat. Laba kotor bukan laba bersih.',
            'transaction_count' => $transactions->count(),
            'summary' => [
                'total_revenue' => $revenue,
                'total_hpp' => $hpp,
                'gross_profit' => $grossProfit,
                'operational_cost' => null,
                'net_profit' => null,
                'cash_in_hand' => null,
                'payments_received' => $payments,
                'tax_collected' => (float) $transactions->sum('tax_amount'),
            ],
            'profit_and_loss' => [
                'gross_revenue' => $revenue,
                'cogs_hpp' => -$hpp,
                'gross_profit' => $grossProfit,
                'expenses' => [],
                'total_expenses' => null,
                'net_profit' => null,
                'profit_margin' => null,
                'gross_margin' => $revenue != 0 ? round($grossProfit / $revenue * 100, 1) : 0,
            ],
            'fund_allocations' => [],
            'payment_methods' => $methods,
        ]]);
    }

    public function export(Request $request): StreamedResponse
    {
        $request->validate(['type' => ['nullable', Rule::in(['csv'])]]);
        $query = $this->transactions($request)->with('items')->orderBy('id');

        return response()->streamDownload(function () use ($query) {
            $file = fopen('php://output', 'w');
            fwrite($file, "\xEF\xBB\xBF");
            fputcsv($file, ['Invoice', 'Tanggal', 'Metode', 'Pendapatan tanpa pajak', 'HPP', 'Laba kotor', 'Pajak', 'Total pembayaran'], ',', '"', '');
            foreach ($query->lazyById(250) as $transaction) {
                $revenue = $transaction->subtotal - $transaction->discount + $transaction->service_fee;
                $hpp = $transaction->items->sum(fn ($item) => $item->cost_price * $item->quantity);
                $safe = static fn ($value) => preg_match('/^[=+@\-\t\r]/', $value) ? "'" . $value : $value;
                fputcsv($file, [
                    $safe($transaction->invoice_number), $transaction->transaction_date->toIso8601String(),
                    $safe($transaction->payment_method), $revenue, $hpp, $revenue - $hpp,
                    $transaction->tax_amount, $transaction->total_amount,
                ], ',', '"', '');
            }
            fclose($file);
        }, 'pakasir-laporan-' . now()->format('Ymd-His') . '.csv', ['Content-Type' => 'text/csv; charset=UTF-8']);
    }
}
