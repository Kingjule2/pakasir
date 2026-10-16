<?php

namespace Tests\Feature;

use App\Models\Transaction;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportExportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
        $this->withToken('vault-demo-token-12345');
        $this->travelTo(now()->startOfMonth()->addDays(10)->setTime(12, 0));
    }

    public function test_period_revenue_excludes_unpaid_orders_and_tax_and_uses_historical_cost(): void
    {
        Transaction::query()->delete();
        $sale = Transaction::create([
            'invoice_number' => 'REPORT-PAID', 'subtotal' => 100000, 'discount' => 10000,
            'service_fee' => 5000, 'tax_amount' => 9900, 'total_amount' => 104900,
            'payment_method' => 'Cash', 'payment_status' => 'paid', 'transaction_date' => now(),
        ]);
        $sale->items()->create([
            'product_name' => 'Historical snapshot', 'quantity' => 2, 'unit_price' => 50000,
            'cost_price' => 20000, 'subtotal' => 100000,
        ]);
        foreach (['pending', 'outside-period'] as $status) {
            Transaction::create([
                'invoice_number' => 'REPORT-' . $status, 'subtotal' => 500000, 'total_amount' => 500000,
                'payment_method' => 'Cash', 'payment_status' => $status === 'pending' ? 'pending' : 'paid',
                'transaction_date' => $status === 'pending' ? now() : now()->subMonth(),
            ]);
        }
        $this->getJson('/api/reports?period=Bulan%20Ini')->assertOk()
            ->assertJsonPath('data.transaction_count', 1)
            ->assertJsonPath('data.summary.total_revenue', 95000)
            ->assertJsonPath('data.summary.total_hpp', 40000)
            ->assertJsonPath('data.summary.gross_profit', 55000)
            ->assertJsonPath('data.summary.net_profit', null)
            ->assertJsonPath('data.summary.tax_collected', 9900);
        $this->getJson('/api/reports?period=unknown')->assertUnprocessable();
        $csv = $this->get('/api/reports/export?period=Bulan%20Ini&type=csv')->assertOk()->streamedContent();
        $this->assertStringContainsString('REPORT-PAID', $csv);
        $this->assertStringNotContainsString('REPORT-pending', $csv);
        $this->assertStringNotContainsString('REPORT-outside-period', $csv);
        $this->assertStringContainsString('95000,40000,55000,9900,104900', $csv);
    }

    public function test_operational_export_is_downloadable_and_excludes_login_secrets(): void
    {
        $response = $this->post('/api/privacy/backup')->assertOk();
        $data = json_decode($response->streamedContent(), true, flags: JSON_THROW_ON_ERROR);
        $this->assertSame('pakasir-operational-export', $data['format']);
        $this->assertSame('SKU-001', $data['products'][0]['sku']);
        $this->assertArrayNotHasKey('users', $data);
        $this->assertStringNotContainsString('vault-demo-token-12345', json_encode($data));
    }
}
