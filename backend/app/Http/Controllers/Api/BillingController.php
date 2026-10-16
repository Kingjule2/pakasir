<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\BillingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BillingController extends Controller
{
    public function __construct(private BillingService $billing) {}

    public function plans()
    {
        return response()->json(['success' => true, 'data' => [
            'plans' => array_values(config('billing.plans')),
            'payment' => ['provider' => 'midtrans', 'ready' => $this->billing->ready(), 'environment' => config('billing.production') ? 'production' : 'sandbox', 'message' => $this->billing->ready() ? 'Pembayaran diverifikasi server melalui Midtrans.' : 'Administrator perlu mengatur MIDTRANS_SERVER_KEY dan webhook HTTPS.'],
            'enterprise_contact' => config('billing.enterprise_contact'),
            'scope' => 'single_store',
        ]]);
    }

    public function subscription(Request $request)
    {
        return response()->json(['success' => true, 'data' => $this->billing->summary($request->user())]);
    }

    private function authorizeOwner(Request $request): void
    {
        if (!$this->billing->canManage($request->user())) {
            $this->billing->fail(403, 'Hanya superadmin pemilik toko yang dapat mengelola pembayaran.');
        }
    }

    public function invoices(Request $request)
    {
        $this->authorizeOwner($request);
        $invoices = DB::table('billing_invoices')->where('user_id', $request->user()->id)->orderByDesc('id')->limit(100)->get()->map(fn ($row) => $this->billing->invoice($row));
        return response()->json(['success' => true, 'data' => $invoices]);
    }

    public function checkout(Request $request)
    {
        $this->authorizeOwner($request);
        $data = $request->validate(['plan' => 'required|in:basic,pro', 'idempotency_key' => 'required|uuid']);
        return response()->json(['success' => true, 'data' => $this->billing->checkout($request->user(), $data['plan'], $data['idempotency_key'])]);
    }

    public function refresh(Request $request, int $id)
    {
        $this->authorizeOwner($request);
        $invoice = DB::table('billing_invoices')->where('user_id', $request->user()->id)->where('id', $id)->first();
        if (!$invoice) {
            $this->billing->fail(404, 'Invoice tidak ditemukan.');
        }
        return response()->json(['success' => true, 'data' => $this->billing->invoice($this->billing->refresh($invoice))]);
    }

    public function webhook(Request $request)
    {
        if (!$this->billing->ready()) {
            $this->billing->fail(503, 'Gateway pembayaran belum dikonfigurasi.');
        }
        $data = $request->validate(['order_id' => 'required|string|max:100', 'status_code' => 'required|string|max:3', 'gross_amount' => 'required|string|max:30', 'signature_key' => 'required|string|size:128']);
        $expected = hash('sha512', $data['order_id'].$data['status_code'].$data['gross_amount'].config('billing.server_key'));
        if (!hash_equals($expected, $data['signature_key'])) {
            $this->billing->fail(403, 'Signature pembayaran tidak valid.');
        }
        $invoice = DB::table('billing_invoices')->where('order_id', $data['order_id'])->first();
        if (!$invoice) {
            $this->billing->fail(404, 'Invoice tidak ditemukan.');
        }
        if (!preg_match('/^\d+(?:\.0{1,2})?$/D', $data['gross_amount']) || (int) $data['gross_amount'] !== (int) $invoice->amount) {
            $this->billing->fail(422, 'Nominal pembayaran tidak sesuai invoice.');
        }
        // Midtrans signature does not cover transaction_status: always query the server.
        $this->billing->refresh($invoice);
        return response()->json(['success' => true, 'message' => 'Notifikasi pembayaran diverifikasi.']);
    }
}
