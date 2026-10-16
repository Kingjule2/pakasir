<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Tests\TestCase;

class BillingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
        config(['billing.server_key' => 'test-server-key', 'billing.production' => false, 'billing.owner_id' => null, 'services.gemini.key' => 'test-gemini']);
        Http::preventStrayRequests();
    }

    private function owner(): self
    {
        return $this->withHeader('Authorization', 'Bearer vault-demo-token-12345');
    }

    private function invoice(string $status = 'pending'): object
    {
        $id = DB::table('billing_invoices')->insertGetId(['user_id' => User::where('role', 'superadmin')->first()->id, 'idempotency_key' => (string) Str::uuid(), 'order_id' => 'PAK-'.Str::uuid(), 'plan' => 'basic', 'amount' => 99000, 'status' => $status, 'created_at' => now(), 'updated_at' => now()]);
        return DB::table('billing_invoices')->find($id);
    }

    private function notification(object $invoice, array $changes = []): array
    {
        $data = array_merge(['order_id' => $invoice->order_id, 'status_code' => '200', 'gross_amount' => '99000.00', 'transaction_status' => 'settlement'], $changes);
        $data['signature_key'] = hash('sha512', $data['order_id'].$data['status_code'].$data['gross_amount'].'test-server-key');
        return $data;
    }

    private function active(string $plan = 'basic', int $limit = 50): void
    {
        DB::table('store_subscriptions')->where('id', 1)->update(['plan' => $plan, 'status' => 'active', 'starts_at' => now(), 'ends_at' => now()->addMonthNoOverflow(), 'prompt_limit' => $limit]);
    }

    public function test_anonymous_business_and_auth_fallback_are_denied(): void
    {
        $this->getJson('/api/auth/me')->assertUnauthorized();
        $this->postJson('/api/auth/logout')->assertUnauthorized();
        $this->postJson('/api/supri/chat', ['message' => 'hello'])->assertUnauthorized();
        $this->postJson('/api/inventory', [])->assertUnauthorized();
        $this->getJson('/api/billing/invoices')->assertUnauthorized();
        $this->getJson('/api/billing/plans')->assertOk()->assertJsonPath('data.plans.0.price', 99000);
    }

    public function test_logout_revokes_token(): void
    {
        $this->owner()->postJson('/api/auth/logout')->assertOk();
        $this->getJson('/api/auth/me')->assertUnauthorized();
    }

    public function test_missing_gateway_creates_no_invoice(): void
    {
        config(['billing.server_key' => '']);
        $this->owner()->postJson('/api/billing/checkout', ['plan' => 'basic', 'idempotency_key' => (string) Str::uuid()])->assertStatus(503);
        $this->assertDatabaseCount('billing_invoices', 0);
        Http::assertNothingSent();
    }

    public function test_checkout_deduplicates_same_and_new_keys_without_activating(): void
    {
        Http::fake(['app.sandbox.midtrans.com/*' => Http::response(['redirect_url' => 'https://app.sandbox.midtrans.com/snap/v4/redirection/test'])]);
        $key = (string) Str::uuid();
        $first = $this->owner()->postJson('/api/billing/checkout', ['plan' => 'basic', 'idempotency_key' => $key])->assertOk();
        $this->postJson('/api/billing/checkout', ['plan' => 'basic', 'idempotency_key' => $key])->assertOk()->assertJsonPath('data.invoice.id', $first->json('data.invoice.id'));
        $this->postJson('/api/billing/checkout', ['plan' => 'basic', 'idempotency_key' => (string) Str::uuid()])->assertOk()->assertJsonPath('data.invoice.id', $first->json('data.invoice.id'));
        $this->assertDatabaseCount('billing_invoices', 1);
        $this->assertDatabaseHas('store_subscriptions', ['id' => 1, 'status' => 'inactive']);
        Http::assertSentCount(1);
    }

    public function test_billing_requires_owner_and_scopes_invoice_lookup(): void
    {
        $invoice = $this->invoice();
        $this->withHeader('Authorization', 'Bearer vault-manager-token-67890')->getJson('/api/billing/invoices/'.$invoice->id)->assertForbidden();
        $this->postJson('/api/billing/checkout', ['plan' => 'pro', 'idempotency_key' => (string) Str::uuid()])->assertForbidden();
        $other = User::create(['name' => 'Other admin', 'email' => 'other@example.test', 'password' => 'secret-password', 'role' => 'superadmin', 'api_token' => 'other-token']);
        DB::table('billing_invoices')->where('id', $invoice->id)->update(['user_id' => $other->id]);
        $this->owner()->getJson('/api/billing/invoices/'.$invoice->id)->assertNotFound();
        $this->getJson('/api/billing/invoices')->assertOk()->assertJsonCount(0, 'data');
        Http::assertNothingSent();
    }

    public function test_invalid_signature_and_wrong_signed_amount_cannot_activate(): void
    {
        $invoice = $this->invoice();
        $data = $this->notification($invoice);
        $data['signature_key'] = str_repeat('0', 128);
        $this->postJson('/api/billing/webhook', $data)->assertForbidden();
        $this->postJson('/api/billing/webhook', $this->notification($invoice, ['gross_amount' => '1.00']))->assertUnprocessable();
        $this->assertDatabaseHas('store_subscriptions', ['status' => 'inactive']);
        Http::assertNothingSent();
    }

    public function test_unsigned_transaction_status_is_not_trusted(): void
    {
        $invoice = $this->invoice();
        Http::fake(['api.sandbox.midtrans.com/*' => Http::response(['order_id' => $invoice->order_id, 'gross_amount' => '99000.00', 'transaction_status' => 'pending'])]);
        $this->postJson('/api/billing/webhook', $this->notification($invoice))->assertOk();
        $this->assertDatabaseHas('billing_invoices', ['id' => $invoice->id, 'status' => 'pending']);
        $this->assertDatabaseHas('store_subscriptions', ['status' => 'inactive']);
    }

    public function test_gateway_amount_mismatch_cannot_activate(): void
    {
        $invoice = $this->invoice();
        Http::fake(['api.sandbox.midtrans.com/*' => Http::response(['order_id' => $invoice->order_id, 'gross_amount' => '1000.00', 'transaction_status' => 'settlement'])]);
        $this->owner()->getJson('/api/billing/invoices/'.$invoice->id)->assertUnprocessable();
        $this->assertDatabaseHas('store_subscriptions', ['status' => 'inactive']);
    }

    public function test_verified_activation_is_idempotent_and_does_not_reset_quota(): void
    {
        $invoice = $this->invoice();
        Http::fake(['api.sandbox.midtrans.com/*' => Http::response(['order_id' => $invoice->order_id, 'gross_amount' => '99000.00', 'transaction_status' => 'settlement', 'currency' => 'IDR'])]);
        $this->postJson('/api/billing/webhook', $this->notification($invoice))->assertOk();
        $sub = DB::table('store_subscriptions')->first();
        DB::table('subscription_usages')->update(['prompts_used' => 7]);
        $this->travel(2)->days();
        $this->postJson('/api/billing/webhook', $this->notification($invoice))->assertOk();
        $this->assertDatabaseHas('store_subscriptions', ['plan' => 'basic', 'ends_at' => $sub->ends_at, 'prompt_limit' => 50]);
        $this->assertDatabaseHas('subscription_usages', ['prompts_used' => 7]);
        $this->assertDatabaseCount('subscription_usages', 1);
        $this->assertDatabaseHas('billing_invoices', ['id' => $invoice->id, 'status' => 'paid']);
    }

    public function test_unpaid_and_expired_subscriptions_cannot_use_ai_or_add_sku(): void
    {
        $this->owner()->postJson('/api/supri/chat', ['message' => 'hello'])->assertStatus(402);
        $this->active();
        $this->travel(32)->days();
        $this->postJson('/api/supri/chat', ['message' => 'hello'])->assertStatus(402);
        $this->getJson('/api/billing/subscription')->assertOk()->assertJsonPath('data.subscription.status', 'expired')->assertJsonPath('data.usage.prompt_limit', 0);
        $this->postJson('/api/inventory', ['name' => 'New', 'sku' => 'EXPIRED', 'category' => 'Test', 'price' => 100, 'cost_price' => 50, 'total_qty' => 1, 'stock_in' => 1])->assertStatus(402);
        Http::assertNothingSent();
    }

    public function test_success_consumes_quota_failure_refunds_and_cap_blocks(): void
    {
        $this->active('basic', 1);
        Http::fake(['generativelanguage.googleapis.com/*' => Http::sequence()->push(['error' => 'unavailable'], 503)->push(['candidates' => [['content' => ['parts' => [['text' => 'Data toko tercatat.']]]]]])]);
        $this->owner()->postJson('/api/supri/chat', ['message' => 'ringkas toko'])->assertStatus(503);
        $this->assertDatabaseHas('subscription_usages', ['prompts_used' => 0]);
        $this->postJson('/api/supri/chat', ['message' => 'ringkas toko'])->assertOk()->assertJsonPath('data.content', 'Data toko tercatat.');
        $this->assertDatabaseHas('subscription_usages', ['prompts_used' => 1]);
        $this->postJson('/api/supri/chat', ['message' => 'sekali lagi'])->assertStatus(429);
        Http::assertSentCount(2);
        Http::assertSent(fn ($request) => $request['generationConfig']['maxOutputTokens'] === 1024 && count($request['contents']) <= 7);
    }

    public function test_sku_cap_and_seat_cap_apply_to_global_store(): void
    {
        $this->active();
        config(['billing.plans.basic.sku_limit' => Product::count()]);
        $this->owner()->postJson('/api/inventory', ['name' => 'New', 'sku' => 'CAPPED', 'category' => 'Test', 'price' => 100, 'cost_price' => 50, 'total_qty' => 1, 'stock_in' => 1])->assertStatus(409);
        $this->getJson('/api/inventory')->assertOk();
        $this->withHeader('Authorization', 'Bearer vault-manager-token-67890')->getJson('/api/inventory')->assertForbidden();
        $this->getJson('/api/billing/subscription')->assertOk()->assertJsonPath('data.can_manage_billing', false)->assertJsonPath('data.usage.user_count', 3);
    }

    public function test_refund_revokes_entitlement_and_stale_settlement_cannot_restore_it(): void
    {
        $invoice = $this->invoice();
        $base = ['order_id' => $invoice->order_id, 'gross_amount' => '99000.00'];
        Http::fake(['api.sandbox.midtrans.com/*' => Http::sequence()
            ->push($base + ['transaction_status' => 'settlement'])
            ->push($base + ['transaction_status' => 'refund'])
            ->push($base + ['transaction_status' => 'settlement'])]);
        $this->postJson('/api/billing/webhook', $this->notification($invoice))->assertOk();
        $this->postJson('/api/billing/webhook', $this->notification($invoice))->assertOk();
        $this->postJson('/api/billing/webhook', $this->notification($invoice))->assertOk();
        $this->assertDatabaseHas('store_subscriptions', ['status' => 'suspended']);
        $this->assertDatabaseHas('billing_invoices', ['id' => $invoice->id, 'status' => 'refund']);
        $this->owner()->postJson('/api/supri/chat', ['message' => 'hello'])->assertStatus(402);
    }

    public function test_oversized_input_is_rejected_before_quota_or_provider_call(): void
    {
        $this->active();
        $this->owner()->postJson('/api/supri/chat', ['message' => str_repeat('a', 4001)])->assertUnprocessable();
        $this->assertDatabaseCount('subscription_usages', 0);
        Http::assertNothingSent();
    }
}
