<?php

namespace Tests\Feature;

use App\Models\Product;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PakasirApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    public function test_api_health_check_returns_ok(): void
    {
        $response = $this->getJson('/api/health');
        $response->assertStatus(200)
            ->assertJson(['status' => 'OK']);
    }

    public function test_auth_login_with_valid_credentials(): void
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'admin@vault-retail.id',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'admin@vault-retail.id');
    }

    public function test_dashboard_endpoint_returns_kpis_and_charts(): void
    {
        $response = $this->getJson('/api/dashboard');
        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'system_status',
                    'kpi' => [
                        'today_sales',
                        'monthly_turnover',
                        'total_customers',
                        'vip_customers',
                        'low_stock_alerts',
                    ],
                    'sales_velocity_chart',
                    'outlets_leaderboard',
                    'top_products',
                ],
            ]);
    }

    public function test_inventory_list_and_add_product(): void
    {
        $response = $this->getJson('/api/inventory');
        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $addResponse = $this->postJson('/api/inventory', [
            'name' => 'Leather Jacket Pro',
            'sku' => 'SKU-TEST-999',
            'category' => 'Fashion',
            'price' => 750000,
            'cost_price' => 450000,
            'total_qty' => 50,
            'stock_in' => 20,
            'priority' => 'high',
            'tag' => 'Fast Moving',
        ]);

        $addResponse->assertStatus(201)
            ->assertJsonPath('data.sku', 'SKU-TEST-999');
    }

    public function test_customers_list_and_filter(): void
    {
        $response = $this->getJson('/api/customers?tier=VIP');
        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertGreaterThanOrEqual(1, count($response->json('data.customers')));
    }

    public function test_stores_toggle_status(): void
    {
        $response = $this->getJson('/api/stores');
        $response->assertStatus(200);

        $firstOutletId = $response->json('data.outlets.0.id');
        $toggleResponse = $this->patchJson("/api/stores/{$firstOutletId}/toggle-status");
        $toggleResponse->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_reports_returns_financial_breakdown(): void
    {
        $response = $this->getJson('/api/reports?period=Bulan+Ini');
        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.summary.total_revenue', 284500000);
    }

    public function test_help_faqs_and_ticket_submission(): void
    {
        $response = $this->getJson('/api/help/faqs');
        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $ticketResponse = $this->postJson('/api/help/tickets', [
            'subject' => 'Kendala Integrasi Printer Thermal USB',
            'category' => 'Hardware & EDC',
            'priority' => 'Tinggi',
            'message' => 'Kertas macet saat auto-cut struk kasir.',
        ]);

        $ticketResponse->assertStatus(201)
            ->assertJsonPath('success', true);
    }
    public function test_settings_update(): void
    {
        $response = $this->putJson('/api/settings', [
            'tax_rate' => 12.0,
            'tax_enabled' => true,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.tax_rate', 12);
    }

    public function test_privacy_and_audit_logs(): void
    {
        $response = $this->getJson('/api/privacy');
        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $logsResponse = $this->getJson('/api/privacy/audit-logs');
        $logsResponse->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_supri_ai_chat_and_restock(): void
    {
        $response = $this->postJson('/api/supri/chat', [
            'message' => 'Berapa laba bersih minggu ini?',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.widget_type', 'financeSummary');

        $restockResponse = $this->postJson('/api/supri/restock-now');
        $restockResponse->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_pos_transaction_checkout_decrements_stock(): void
    {
        $product = Product::first();
        $initialStock = $product->stock_in;

        $response = $this->postJson('/api/transactions', [
            'items' => [
                [
                    'product_id' => $product->id,
                    'quantity' => 2,
                ],
            ],
            'payment_method' => 'QRIS',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true);

        $this->assertEquals($initialStock - 2, $product->fresh()->stock_in);
    }

    public function test_neural_memory_training_and_sales_marketing_analysis(): void
    {
        // Train new memory
        $trainResponse = $this->postJson('/api/supri/train-memory', [
            'content' => 'Pelanggan baru yang beli via TikTok Shop mendapatkan gratis stiker dan kupon 15%.',
            'type' => 'marketing_rule',
            'importance' => 9,
        ]);

        $trainResponse->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.memory_type', 'marketing_rule');

        // Get memories list
        $memoriesResponse = $this->getJson('/api/supri/memories');
        $memoriesResponse->assertStatus(200)
            ->assertJsonPath('success', true);
        $this->assertGreaterThanOrEqual(1, $memoriesResponse->json('data.total_memories'));

        // Get deep sales analysis & marketing recommendations
        $analysisResponse = $this->getJson('/api/supri/sales-analysis');
        $analysisResponse->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'sales_summary',
                    'trends' => [
                        'peak_velocity_day',
                        'peak_velocity_hours',
                    ],
                    'marketing_recommendations',
                ],
            ]);
    }

    public function test_natural_human_conversation_responses(): void
    {
        // 1. Natural thanks ("ok makasi supro")
        $thanks = $this->postJson('/api/supri/chat', [
            'message' => 'ok makasi supro',
        ]);
        $thanks->assertStatus(200);
        $content1 = strtolower($thanks->json('data.content'));
        $this->assertTrue(str_contains($content1, 'sama-sama') || str_contains($content1, 'santai') || str_contains($content1, 'seneng'));
        $this->assertFalse(str_contains($content1, 'bos bisa tanya:'));

        // 2. CSV report request ("pri bisa ga bikinin laporan dalam bentuk csv")
        $csvReq = $this->postJson('/api/supri/chat', [
            'message' => 'pri bisa ga bikinin laporan dalam bentuk csv',
        ]);
        $csvReq->assertStatus(200);
        $content2 = strtolower($csvReq->json('data.content'));
        $this->assertTrue(str_contains($content2, 'report') || str_contains($content2, 'csv'));
        $this->assertFalse(str_contains($content2, 'bos bisa tanya:'));
    }
}
