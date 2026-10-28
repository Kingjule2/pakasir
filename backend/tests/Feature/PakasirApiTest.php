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
        $this->withHeader('Authorization', 'Bearer vault-demo-token-12345');
        \Illuminate\Support\Facades\DB::table('store_subscriptions')->where('id', 1)->update([
            'plan' => 'pro', 'status' => 'active', 'starts_at' => now(), 'ends_at' => now()->addMonthNoOverflow(), 'prompt_limit' => 2000,
        ]);
        config(['services.gemini.key' => '']);
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

        $response->assertStatus(503)->assertJsonPath('success', false);

        $restockResponse = $this->postJson('/api/supri/restock-now', [
            'items' => [['product_id' => Product::first()->id, 'qty' => 10]],
        ]);
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

    public function test_ai_without_provider_does_not_fabricate_conversation(): void
    {
        $before = \App\Models\AiMessage::count();
        $this->postJson('/api/supri/chat', ['message' => 'ok makasi supro'])
            ->assertStatus(503)->assertJsonPath('success', false);
        $this->assertSame($before, \App\Models\AiMessage::count());
        $this->assertSame(0, (int) \Illuminate\Support\Facades\DB::table('subscription_usages')->sum('prompts_used'));
    }

    public function test_inventory_soft_delete_recently_deleted_restore_and_purge(): void
    {
        $product = Product::first();
        $initialActiveCount = $this->getJson('/api/inventory')->json('data.total_items');

        // Soft delete product
        $softDelete = $this->postJson("/api/inventory/{$product->id}/soft-delete", [
            'reason' => 'Discontinued',
            'hold_days' => 14,
        ]);
        $softDelete->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.deletedReason', 'Discontinued');

        // Active inventory count decreases by 1
        $this->assertEquals($initialActiveCount - 1, $this->getJson('/api/inventory')->json('data.total_items'));

        // Recently deleted returns the product with retention metadata
        $trash = $this->getJson('/api/inventory/recently-deleted');
        $trash->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.total_items', 1)
            ->assertJsonPath('data.items.0.id', $product->id)
            ->assertJsonPath('data.items.0.deletedReason', 'Discontinued');

        // Restore product back to active catalog
        $restore = $this->postJson("/api/inventory/{$product->id}/restore");
        $restore->assertStatus(200)->assertJsonPath('success', true);
        $this->assertEquals($initialActiveCount, $this->getJson('/api/inventory')->json('data.total_items'));
        $this->assertEquals(0, $this->getJson('/api/inventory/recently-deleted')->json('data.total_items'));

        // Soft delete again and force purge
        $this->postJson("/api/inventory/{$product->id}/soft-delete", ['reason' => 'Expired']);
        $purge = $this->postJson('/api/inventory/purge-expired', ['force' => true]);
        $purge->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.purged_count', 1);
    }

    public function test_voice_transcribe_and_blueprint_memory_training(): void
    {
        $voice = $this->postJson('/api/voice-transcribe', [
            'text' => 'Restock stok kritis sekarang',
            'locale' => 'id-ID',
        ]);
        $voice->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.text', 'Restock stok kritis sekarang')
            ->assertJsonPath('data.locale', 'id-ID');

        $train = $this->postJson('/api/supri/train-memory', [
            'category' => 'Aturan Bisnis',
            'key' => 'Restock Margin',
            'value' => 'Minimal margin 25%',
            'weight' => 0.9,
        ]);
        $train->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.memory_type', 'business_rule');
    }

    public function test_tts_voice_endpoint_validation_and_proxy(): void
    {
        $empty = $this->getJson('/api/tts');
        $empty->assertStatus(400)->assertJsonPath('success', false);

        \Illuminate\Support\Facades\Http::fake([
            'http://127.0.0.1:8000/api/tts*' => \Illuminate\Support\Facades\Http::response('fake-mp3-audio-content', 200, [
                'Content-Type' => 'audio/mpeg',
                'X-Supri-Voice' => 'id-ID-ArdiNeural',
                'X-Supri-Rate' => '+8%',
                'X-Supri-Pitch' => '+0Hz',
            ]),
        ]);

        $res = $this->get('/api/tts?text=Halo+bos');
        $res->assertStatus(200)
            ->assertHeader('Content-Type', 'audio/mpeg')
            ->assertHeader('X-Supri-Voice', 'id-ID-ArdiNeural')
            ->assertHeader('X-Supri-Rate', '+8%')
            ->assertHeader('X-Supri-Pitch', '+0Hz');
        $this->assertEquals('fake-mp3-audio-content', $res->getContent());
    }

    public function test_tts_voice_endpoint_cache_and_fallback(): void
    {
        $cacheDir = storage_path('app/tts_cache');
        if (!is_dir($cacheDir)) {
            @mkdir($cacheDir, 0755, true);
        }
        $voice = 'id-ID-ArdiNeural';
        $rate = '+8%';
        $pitch = '+0Hz';
        $text = 'Tes Cache Audio Ardi';
        $cacheKey = md5("{$voice}_{$rate}_{$pitch}_{$text}");
        $cacheFile = $cacheDir . DIRECTORY_SEPARATOR . $cacheKey . '.mp3';
        file_put_contents($cacheFile, str_repeat('audiomp3cachedata', 20));

        try {
            $res = $this->get('/api/tts?text=' . urlencode($text));
            $res->assertStatus(200)
                ->assertHeader('Content-Type', 'audio/mpeg')
                ->assertHeader('X-Supri-Voice', 'id-ID-ArdiNeural')
                ->assertHeader('Cache-Control', 'max-age=86400, public');
            $this->assertEquals(str_repeat('audiomp3cachedata', 20), $res->getContent());
        } finally {
            @unlink($cacheFile);
        }
    }
}
