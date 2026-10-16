<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\StoreSetting;
use App\Models\Transaction;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CheckoutStockTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
        $this->withToken('vault-demo-token-12345');
    }

    public function test_rejected_checkout_rolls_back_stock_and_does_not_create_an_invoice(): void
    {
        $first = Product::findOrFail(1);
        $second = Product::findOrFail(2);
        $count = Transaction::count();
        $this->postJson('/api/transactions', [
            'items' => [
                ['product_id' => $first->id, 'quantity' => 1],
                ['product_id' => $second->id, 'quantity' => $second->stock_in + 1],
            ], 'payment_method' => 'Cash',
        ])->assertUnprocessable();
        $this->assertSame($first->stock_in, $first->fresh()->stock_in);
        $this->assertSame($second->stock_in, $second->fresh()->stock_in);
        $this->assertSame($count, Transaction::count());
    }

    public function test_checkout_uses_saved_tax_and_service_fee_instead_of_client_totals(): void
    {
        StoreSetting::first()->update(['tax_enabled' => false, 'service_fee_enabled' => true, 'service_fee_rate' => 5]);
        $product = Product::first();
        $subtotal = $product->price;
        $response = $this->postJson('/api/transactions', [
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
            'payment_method' => 'Cash', 'discount' => 10000, 'service_fee' => 999999,
        ])->assertCreated();
        $this->assertEquals(0, $response->json('data.tax_amount'));
        $this->assertEquals(round(($subtotal - 10000) * 0.05, 2), $response->json('data.service_fee'));
        $this->assertEquals(round(($subtotal - 10000) * 1.05, 2), $response->json('data.total_amount'));
    }
}
