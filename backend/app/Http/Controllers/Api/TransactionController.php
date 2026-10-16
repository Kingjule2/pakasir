<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Product;
use App\Models\SecurityAuditLog;
use App\Models\Transaction;
use App\Models\StoreSetting;
use App\Models\TransactionItem;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

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
            'items' => 'required|array|min:1|max:200',
            'items.*.product_id' => 'required|integer|distinct|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1|max:1000000',
            'payment_method' => ['required', Rule::in(['QRIS', 'EDC', 'Cash', 'Transfer'])],
            'discount' => 'nullable|numeric|min:0',
            'customer_id' => 'nullable|integer|exists:customers,id',
            'store_outlet_id' => 'nullable|integer|exists:store_outlets,id',
        ]);

        return DB::transaction(function () use ($request) {
            $subtotal = 0;
            $itemsData = [];

            foreach (collect($request->items)->sortBy('product_id') as $it) {
                $prod = Product::whereKey($it['product_id'])->lockForUpdate()->firstOrFail();
                $qty = (int) $it['quantity'];
                if (!$prod->is_active || $qty > $prod->stock_in) {
                    throw ValidationException::withMessages(['items' => "Stok {$prod->name} tidak mencukupi atau produk tidak aktif."]);
                }
                $itemSubtotal = $prod->price * $qty;
                $subtotal += $itemSubtotal;

                $prod->stock_in -= $qty;
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
            if ($discount > $subtotal) {
                throw ValidationException::withMessages(['discount' => 'Diskon tidak boleh melebihi subtotal.']);
            }
            $settings = StoreSetting::first();
            $taxRate = $settings?->tax_enabled ? $settings->tax_rate / 100 : 0;
            $feeRate = $settings?->service_fee_enabled ? $settings->service_fee_rate / 100 : 0;
            $taxAmount = round(($subtotal - $discount) * $taxRate, 2);
            $serviceFee = round(($subtotal - $discount) * $feeRate, 2);
            $totalAmount = round($subtotal - $discount + $taxAmount + $serviceFee, 2);

            $invoiceNumber = 'INV-' . Str::ulid();

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
