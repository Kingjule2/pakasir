<?php

namespace App\Services;

use App\Models\Product;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class BillingService
{
    public function fail(int $status, string $message): never
    {
        throw new HttpResponseException(response()->json(['success' => false, 'message' => $message], $status));
    }

    public function ownerId(): ?int
    {
        $configured = config('billing.owner_id');
        return $configured ? (int) $configured : User::where('role', 'superadmin')->orderBy('id')->value('id');
    }

    public function canManage(User $user): bool
    {
        return $user->role === 'superadmin' && $user->id === $this->ownerId();
    }

    public function ready(): bool
    {
        $key = (string) config('billing.server_key');
        return $key !== '' && !str_contains(strtoupper($key), 'YOUR_');
    }

    public function activeSubscription(): ?object
    {
        return DB::table('store_subscriptions')->where('id', 1)->where('status', 'active')->where('ends_at', '>', now())->first();
    }

    public function seatAllowed(User $user): bool
    {
        $subscription = $this->activeSubscription();
        if (!$subscription || $user->id === $this->ownerId()) {
            return true;
        }
        $limit = config("billing.plans.{$subscription->plan}.user_limit");
        if ($limit === null) {
            return true;
        }
        // Existing accounts remain intact. Owner is seat one; staff seats use stable ID order.
        return User::where('id', '!=', $this->ownerId())->orderBy('id')->limit(max(0, $limit - 1))->pluck('id')->contains($user->id);
    }

    public function summary(User $user): array
    {
        $row = DB::table('store_subscriptions')->where('id', 1)->first();
        $active = $this->activeSubscription();
        $plan = $active ? config("billing.plans.{$active->plan}") : null;
        $usage = $active ? DB::table('subscription_usages')->where('period_start', $active->starts_at)->value('prompts_used') : 0;
        return [
            'scope' => 'single_store',
            'can_manage_billing' => $this->canManage($user),
            'subscription' => $row && $row->plan ? ['plan' => $row->plan, 'status' => $active ? 'active' : ($row->status === 'active' ? 'expired' : $row->status), 'starts_at' => $row->starts_at, 'ends_at' => $row->ends_at] : null,
            'usage' => ['prompts_used' => (int) $usage, 'prompt_limit' => $active ? $active->prompt_limit : 0, 'sku_count' => Product::count(), 'sku_limit' => $plan['sku_limit'] ?? ($active ? null : 0), 'user_count' => User::count(), 'user_limit' => $plan['user_limit'] ?? ($active ? null : 0)],
            'ai' => ['ready' => (bool) config('services.gemini.key'), 'message' => config('services.gemini.key') ? 'Gemini dikonfigurasi; ketersediaan mengikuti penyedia.' : 'Administrator perlu mengatur GEMINI_API_KEY.'],
        ];
    }

    public function reservePrompt(): int
    {
        return DB::transaction(function () {
            $sub = DB::table('store_subscriptions')->where('id', 1)->lockForUpdate()->first();
            if (!$sub || $sub->status !== 'active' || !$sub->ends_at || Carbon::parse($sub->ends_at)->lte(now())) {
                $this->fail(402, 'Langganan berbayar aktif diperlukan untuk Supri AI.');
            }
            if (!$sub->prompt_limit) {
                $this->fail(403, 'Anggaran prompt Enterprise belum dikonfigurasi sesuai kesepakatan.');
            }
            DB::table('subscription_usages')->insertOrIgnore(['period_start' => $sub->starts_at, 'period_end' => $sub->ends_at, 'prompts_used' => 0, 'created_at' => now(), 'updated_at' => now()]);
            $usage = DB::table('subscription_usages')->where('period_start', $sub->starts_at);
            if (!(clone $usage)->where('prompts_used', '<', $sub->prompt_limit)->increment('prompts_used')) {
                $this->fail(429, 'Kuota prompt periode langganan ini telah habis.');
            }
            return (int) $usage->value('id');
        }, 3);
    }

    public function releasePrompt(int $usageId): void
    {
        DB::table('subscription_usages')->where('id', $usageId)->where('prompts_used', '>', 0)->decrement('prompts_used');
    }

    public function createProduct(array $attributes): Product
    {
        return DB::transaction(function () use ($attributes) {
            $sub = DB::table('store_subscriptions')->where('id', 1)->lockForUpdate()->first();
            if (!$sub || $sub->status !== 'active' || !$sub->ends_at || Carbon::parse($sub->ends_at)->lte(now())) {
                $this->fail(402, 'Aktifkan langganan untuk menambah SKU baru. Produk lama tetap dapat dikelola.');
            }
            $limit = config("billing.plans.{$sub->plan}.sku_limit");
            if ($limit !== null && Product::count() >= $limit) {
                $this->fail(409, 'Batas SKU paket tercapai. Hapus SKU tidak terpakai atau tingkatkan paket.');
            }
            return Product::create($attributes);
        }, 3);
    }

    public function invoice(object $invoice): array
    {
        return array_intersect_key((array) $invoice, array_flip(['id', 'order_id', 'plan', 'amount', 'status', 'redirect_url', 'paid_at', 'created_at']));
    }

    private function gateway(string $path, ?array $payload = null): array
    {
        if (!$this->ready()) {
            $this->fail(503, 'Pembayaran belum tersedia. Administrator perlu mengatur MIDTRANS_SERVER_KEY dan webhook HTTPS.');
        }
        $production = config('billing.production');
        $base = $payload === null ? ($production ? 'https://api.midtrans.com' : 'https://api.sandbox.midtrans.com') : ($production ? 'https://app.midtrans.com' : 'https://app.sandbox.midtrans.com');
        try {
            $client = Http::withBasicAuth(config('billing.server_key'), '')->acceptJson()->connectTimeout(5)->timeout(20);
            $response = $payload === null ? $client->get($base.$path) : $client->post($base.$path, $payload);
        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            $this->fail(503, 'Midtrans tidak dapat dihubungi. Jangan membayar ulang; periksa status invoice sebelum mencoba lagi.');
        }
        if ($payload !== null && in_array($response->status(), [400, 401, 403, 404, 422], true)) {
            DB::table('billing_invoices')->where('order_id', $payload['transaction_details']['order_id'])
                ->where('status', 'creating')->update(['status' => 'failure', 'updated_at' => now()]);
        }
        if (!$response->successful() || !is_array($response->json())) {
            $this->fail(503, 'Midtrans belum dapat memproses permintaan. Periksa konfigurasi atau status invoice.');
        }
        return $response->json();
    }

    public function checkout(User $user, string $planId, string $key): array
    {
        if (!$this->ready()) {
            $this->fail(503, 'Pembayaran belum tersedia. Administrator perlu mengatur MIDTRANS_SERVER_KEY dan webhook HTTPS.');
        }
        $plan = config("billing.plans.$planId");
        [$invoice, $created] = DB::transaction(function () use ($user, $planId, $key, $plan) {
            $sub = DB::table('store_subscriptions')->where('id', 1)->lockForUpdate()->first();
            $existing = DB::table('billing_invoices')->where('user_id', $user->id)->where('idempotency_key', $key)->first();
            if ($existing) {
                if ($existing->plan !== $planId) {
                    $this->fail(409, 'Kunci checkout ini sudah digunakan untuk paket lain.');
                }
                return [$existing, false];
            }
            if ($sub->status === 'active' && Carbon::parse($sub->ends_at)->gt(now())) {
                $this->fail(409, 'Paket masih aktif. Pembaruan atau perubahan paket tersedia setelah periode berakhir.');
            }
            if ($plan['sku_limit'] !== null && Product::count() > $plan['sku_limit']) {
                $this->fail(409, 'Jumlah SKU toko melebihi batas paket yang dipilih.');
            }
            $pending = DB::table('billing_invoices')->where('user_id', $user->id)->whereIn('status', ['creating', 'pending'])->first();
            if ($pending) {
                if ($pending->plan !== $planId) {
                    $this->fail(409, 'Selesaikan atau tunggu invoice tertunda berakhir sebelum memilih paket lain.');
                }
                return [$pending, false];
            }
            $id = DB::table('billing_invoices')->insertGetId(['user_id' => $user->id, 'idempotency_key' => $key, 'order_id' => 'PAK-'.Str::uuid(), 'plan' => $planId, 'amount' => $plan['price'], 'status' => 'creating', 'created_at' => now(), 'updated_at' => now()]);
            return [DB::table('billing_invoices')->find($id), true];
        }, 3);
        if (!$created) {
            if ($invoice->status === 'creating') {
                $this->fail(409, 'Checkout sedang diproses atau status gateway belum pasti. Segarkan invoice; jangan membuat pembayaran ganda.');
            }
            return ['invoice' => $this->invoice($invoice), 'redirect_url' => $invoice->redirect_url];
        }
        // Never retry a timed-out creation with a new order: it might already exist at Midtrans.
        $data = $this->gateway('/snap/v1/transactions', ['transaction_details' => ['order_id' => $invoice->order_id, 'gross_amount' => $invoice->amount], 'item_details' => [['id' => $planId, 'price' => $invoice->amount, 'quantity' => 1, 'name' => 'Pakasir '.$plan['name'].' - 1 bulan']], 'customer_details' => ['first_name' => $user->name, 'email' => $user->email], 'expiry' => ['unit' => 'hours', 'duration' => 24]]);
        $url = $data['redirect_url'] ?? '';
        $expectedHost = config('billing.production') ? 'app.midtrans.com' : 'app.sandbox.midtrans.com';
        if (parse_url($url, PHP_URL_SCHEME) !== 'https' || parse_url($url, PHP_URL_HOST) !== $expectedHost) {
            $this->fail(503, 'Midtrans tidak mengembalikan tautan pembayaran yang valid.');
        }
        DB::table('billing_invoices')->where('id', $invoice->id)->where('status', 'creating')->update(['status' => 'pending', 'redirect_url' => $url, 'updated_at' => now()]);
        $invoice = DB::table('billing_invoices')->find($invoice->id);
        return ['invoice' => $this->invoice($invoice), 'redirect_url' => $invoice->redirect_url];
    }

    public function refresh(object $invoice): object
    {
        $data = $this->gateway('/v2/'.rawurlencode($invoice->order_id).'/status');
        return $this->applyVerifiedStatus($invoice, $data);
    }

    public function applyVerifiedStatus(object $invoice, array $data): object
    {
        $amount = (string) ($data['gross_amount'] ?? '');
        if (($data['order_id'] ?? null) !== $invoice->order_id || !preg_match('/^\d+(?:\.0{1,2})?$/D', $amount) || (int) $amount !== (int) $invoice->amount || (isset($data['currency']) && $data['currency'] !== 'IDR')) {
            $this->fail(422, 'Order atau nominal pembayaran tidak sesuai invoice.');
        }
        $status = $data['transaction_status'] ?? '';
        $fraud = $data['fraud_status'] ?? null;
        $paid = ($status === 'settlement' && ($fraud === null || $fraud === 'accept')) || ($status === 'capture' && $fraud === 'accept');
        return DB::transaction(function () use ($invoice, $status, $paid) {
            $sub = DB::table('store_subscriptions')->where('id', 1)->lockForUpdate()->first();
            $current = DB::table('billing_invoices')->where('id', $invoice->id)->lockForUpdate()->first();
            if (in_array($status, ['refund', 'partial_refund', 'chargeback', 'partial_chargeback'], true)) {
                DB::table('billing_invoices')->where('id', $current->id)->update(['status' => $status, 'updated_at' => now()]);
                if ((int) $sub->billing_invoice_id === (int) $current->id) {
                    DB::table('store_subscriptions')->where('id', 1)->update(['status' => 'suspended', 'updated_at' => now()]);
                }
                return DB::table('billing_invoices')->find($current->id);
            }
            if ($current->paid_at) {
                return $current; // Duplicate/out-of-order notifications never extend entitlement.
            }
            if ($paid) {
                $start = now();
                $end = $start->copy()->addMonthNoOverflow();
                DB::table('billing_invoices')->where('id', $invoice->id)->update(['status' => 'paid', 'paid_at' => $start, 'updated_at' => $start]);
                DB::table('store_subscriptions')->where('id', 1)->update(['plan' => $current->plan, 'status' => 'active', 'starts_at' => $start, 'ends_at' => $end, 'prompt_limit' => config("billing.plans.{$current->plan}.prompt_limit"), 'billing_invoice_id' => $current->id, 'updated_at' => $start]);
                DB::table('subscription_usages')->insertOrIgnore(['period_start' => $start, 'period_end' => $end, 'prompts_used' => 0, 'created_at' => $start, 'updated_at' => $start]);
            } elseif (in_array($status, ['pending', 'deny', 'cancel', 'expire', 'failure'], true)) {
                DB::table('billing_invoices')->where('id', $invoice->id)->update(['status' => $status === 'pending' ? 'pending' : $status, 'updated_at' => now()]);
            }
            return DB::table('billing_invoices')->find($invoice->id);
        }, 3);
    }
}
