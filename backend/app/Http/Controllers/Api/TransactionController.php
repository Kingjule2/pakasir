<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Product;
use App\Models\SecurityAuditLog;
use App\Models\Transaction;
use App\Models\TransactionItem;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $transactions = Transaction::with(['customer', 'outlet', 'items'])
            ->orderBy('id', 'desc')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $transactions,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'payment_method' => 'required|string',
        ]);

        return DB::transaction(function () use ($request) {
            $subtotal = 0;
            $itemsData = [];

            foreach ($request->items as $it) {
                $prod = Product::findOrFail($it['product_id']);
                $qty = (int) $it['quantity'];
                $itemSubtotal = $prod->price * $qty;
                $subtotal += $itemSubtotal;

                // Decrement stock
                $prod->stock_in = max(0, $prod->stock_in - $qty);
                if ($prod->stock_in <= 0) {
                    $prod->is_out_of_stock = true;
                }
                $prod->save();

                $itemsData[] = [
                    'product_id' => $prod->id,
                    'product_name' => $prod->name,
                    'quantity' => $qty,
                    'unit_price' => $prod->price,
                    'cost_price' => $prod->cost_price,
                    'subtotal' => $itemSubtotal,
                ];
            }

            $discount = (float) ($request->discount ?? 0);
            $taxRate = 0.11; // 11% PPN
            $taxAmount = ($subtotal - $discount) * $taxRate;
            $serviceFee = (float) ($request->service_fee ?? 0);
            $totalAmount = ($subtotal - $discount) + $taxAmount + $serviceFee;

            $invoiceNumber = 'INV-' . date('Ymd') . '-' . str_pad((string) (Transaction::count() + 1), 4, '0', STR_PAD_LEFT);

            $transaction = Transaction::create([
                'store_outlet_id' => $request->store_outlet_id ?? 1,
                'customer_id' => $request->customer_id ?? null,
                'invoice_number' => $invoiceNumber,
                'subtotal' => $subtotal,
                'discount' => $discount,
                'tax_amount' => $taxAmount,
                'service_fee' => $serviceFee,
                'total_amount' => $totalAmount,
                'payment_method' => $request->payment_method,
                'payment_status' => 'paid',
                'transaction_date' => Carbon::now(),
            ]);

            foreach ($itemsData as $item) {
                $transaction->items()->create($item);
            }

            // Update customer spending & order count if customer attached
            if ($request->customer_id) {
                $cust = Customer::find($request->customer_id);
                if ($cust) {
                    $cust->total_orders += 1;
                    $cust->total_spent += $totalAmount;
                    $cust->last_active = 'Baru saja';
                    $cust->save();
                }
            }

            SecurityAuditLog::create([
                'user' => 'Kasir POS',
                'role' => 'Kasir',
                'action' => "Transaksi Baru Selesai: #{$invoiceNumber} (Total: Rp " . number_format($totalAmount, 0, ',', '.') . ")",
                'target' => 'POS Terminal',
                'ip_address' => $request->ip(),
                'status' => 'Sukses',
            ]);

            return response()->json([
                'success' => true,
                'message' => "Transaksi #{$invoiceNumber} berhasil diproses.",
                'data' => $transaction->load('items'),
            ], 201);
        });
    }

    public function show(int $id): JsonResponse
    {
        $transaction = Transaction::with(['customer', 'outlet', 'items'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $transaction,
        ]);
    }
}
