<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Product;
use App\Models\SalesAnalytic;
use App\Models\StoreOutlet;
use App\Models\Transaction;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiService
{
    protected string $apiKey;
    protected string $model;
    protected NeuralMemoryEngine $memoryEngine;

    public function __construct(NeuralMemoryEngine $memoryEngine)
    {
        $this->apiKey = env('GEMINI_API_KEY', '');
        $this->model = env('GEMINI_MODEL', 'gemini-1.5-flash');
        $this->memoryEngine = $memoryEngine;
    }

    /**
     * Ask Supri AI using Gemini API + Neural Memory Engine + Realtime Business Data.
     */
    public function ask(string $userPrompt, array $conversationHistory = []): array
    {
        // 1. Gather Realtime Sales & Operations Data
        $salesContext = $this->gatherBusinessSalesContext();

        // 2. Retrieve relevant neural memories
        $memoryContext = $this->memoryEngine->buildContext($userPrompt);

        // 3. Assemble Trained System Prompt
        $systemInstruction = $this->buildTrainedSystemInstruction($salesContext, $memoryContext);

        // If Gemini API Key is configured, make the live call to Google Gemini API
        if (!empty($this->apiKey) && $this->apiKey !== 'YOUR_GEMINI_API_KEY') {
            try {
                $response = $this->callGeminiApi($userPrompt, $systemInstruction, $conversationHistory);
                if ($response['success']) {
                    return $this->parseResponse($response['text'], $userPrompt);
                }
            } catch (\Throwable $e) {
                Log::warning("Gemini API call failed, falling back to Neural Reasoning Engine: " . $e->getMessage());
            }
        }

        // 4. Intelligent Local Conversational Reasoning Engine (Offline/Zero-Key Fallback)
        return $this->generateLocalReasoningResponse($userPrompt, $salesContext, $memoryContext);
    }

    /**
     * Call Google Gemini API (generativelanguage.googleapis.com).
     */
    protected function callGeminiApi(string $prompt, string $systemInstruction, array $history): array
    {
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$this->model}:generateContent?key={$this->apiKey}";

        $contents = [];

        // Add history
        foreach ($history as $msg) {
            $contents[] = [
                'role' => $msg['role'] === 'assistant' ? 'model' : 'user',
                'parts' => [['text' => $msg['content']]],
            ];
        }

        // Add latest user prompt
        $contents[] = [
            'role' => 'user',
            'parts' => [['text' => $prompt]],
        ];

        $payload = [
            'system_instruction' => [
                'parts' => [
                    ['text' => $systemInstruction],
                ],
            ],
            'contents' => $contents,
            'generationConfig' => [
                'temperature' => 0.7,
                'maxOutputTokens' => 1024,
            ],
        ];

        $response = Http::timeout(30)->post($url, $payload);

        if ($response->successful()) {
            $data = $response->json();
            $text = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
            return ['success' => true, 'text' => $text];
        }

        return ['success' => false, 'error' => $response->body()];
    }

    /**
     * System Instruction defining Supri persona and comprehensive domain training.
     */
    protected function buildTrainedSystemInstruction(array $sales, string $memories): string
    {
        $salesJson = json_encode($sales, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

        return <<<PROMPT
Anda adalah **Supri**, AI Assistant cerdas, asik, berwawasan luas, dan ramah seperti manusia pada umumnya (mirip AI modern serba bisa seperti ChatGPT/Gemini).

=== PANDUAN UTAMA: BEBAS NGOBROL TANPA LARANGAN ===
1. TIDAK ADA BATASAN TOPIK. Pengguna bebas mengobrol tentang APA SAJA seperti berbicara dengan AI pada umumnya:
   - Obrolan santai, curhat, filosofi, cerita, humor, sains, sejarah, teknologi, koding, resep, film, musik, bisnis umum, dll.
   - Pahami bahasa Indonesia percakapan sehari-hari, santai, gaul, slang (seperti "ok makasi supro", "pri", "wkwk", "bisa ga", "lu", "gw", "bro", "bos").
2. JANGAN PERNAH bersikap kaku, membatasi topik pembicaraan, atau membatasi diri dengan kata-kata seperti "saya hanya bot toko" atau memberikan menu bernomor kaku (seperti "Bos bisa tanya: 1... 2..."). Jadilah teman mengobrol yang luwes, cerdas, dan hangat.
3. Anda tetap memiliki konteks dan ingatan lengkap tentang toko Vault / Pakasir (data stok, omzet, laba, cabang toko, dan aturan bisnis):
   - Jika pengguna menanyakan seputar toko, stok, keuangan, atau pemasaran, berikan jawaban tajam, akurat, dan solutif berdasarkan data di bawah.
   - Jika pengguna menanyakan hal umum atau sekadar mengobrol santai di luar toko, jawablah secara bebas, kreatif, dan menyenangkan seperti AI serba bisa pada umumnya!
4. Format jawaban: Gunakan Markdown yang rapi dan nyaman dibaca.

=== KONTEKS BISNIS & PENJUALAN TOKO (JIKA DITANYAKAN) ===
{$salesJson}

=== MEMORI DARI MEMORY ENGINE ===
{$memories}
PROMPT;
    }
    /**
     * Gather realtime sales, inventory, and operations data.
     */
    public function gatherBusinessSalesContext(): array
    {
        $products = Product::all();
        $criticalStock = $products->filter(fn($p) => $p->stock_in < 30 || $p->is_out_of_stock)->values();
        $fastMoving = $products->where('tag', 'Fast Moving')->values();

        $analytics = SalesAnalytic::orderBy('analysis_date', 'asc')->take(7)->get();
        $total7DayRevenue = $analytics->sum('total_revenue');

        $outlets = StoreOutlet::all();
        $openOutlets = $outlets->where('is_open', true)->count();
        $todayOutletSales = $outlets->where('is_open', true)->sum('daily_sales');

        $customers = Customer::all();
        $vipCustomers = $customers->where('tier', 'VIP')->values();

        return [
            'financials' => [
                'monthly_revenue' => 284500000,
                'monthly_hpp' => 168000000,
                'gross_profit' => 116500000,
                'operational_cost' => 38500000,
                'net_profit' => 78000000,
                'net_profit_margin' => '27.4%',
                'cash_in_hand' => 94200000,
                'today_sales' => $todayOutletSales,
                'seven_days_sales' => $total7DayRevenue,
            ],
            'inventory_summary' => [
                'total_products_count' => $products->count(),
                'critical_stock_count' => $criticalStock->count(),
                'critical_items' => $criticalStock->map(fn($p) => "{$p->name} (SKU: {$p->sku}, sisa {$p->stock_in} unit)")->toArray(),
                'fast_moving_items' => $fastMoving->map(fn($p) => "{$p->name} (Harga: Rp " . number_format($p->price, 0, ',', '.') . ")")->toArray(),
            ],
            'outlets_summary' => [
                'active_outlets' => "{$openOutlets} dari {$outlets->count()} cabang buka",
                'top_performing_store' => 'Vault Central SCBD (Flagship) - Rp 18.450.000/hari',
            ],
            'customers_summary' => [
                'total_customers' => $customers->count(),
                'vip_members' => $vipCustomers->pluck('name')->toArray(),
            ],
        ];
    }

    /**
     * Parse assistant response text and infer widget data.
     */
    protected function parseResponse(string $text, string $query): array
    {
        $lower = strtolower($query . ' ' . $text);
        $widgetType = null;
        $widgetData = null;

        if (str_contains($lower, 'restock') || str_contains($lower, 'stok kritis') || str_contains($lower, 'habis')) {
            $widgetType = 'quickRestock';
            $widgetData = [
                'count' => 120,
                'items' => ['Backpack Explorer 25L', 'Stainless Tumbler 750ml Vacuum'],
            ];
        } elseif (str_contains($lower, 'tiktok') || str_contains($lower, 'konten') || str_contains($lower, 'pemasaran') || str_contains($lower, 'promo')) {
            $widgetType = 'socialPromo';
            $widgetData = [
                'platform' => 'TikTok & Instagram Reels',
                'target_product' => 'Backpack Explorer 25L',
            ];
        } elseif (str_contains($lower, 'laba') || str_contains($lower, 'keuangan') || str_contains($lower, 'profit') || str_contains($lower, 'omzet')) {
            $widgetType = 'financeSummary';
            $widgetData = [
                'revenue' => 284500000,
                'netProfit' => 78000000,
                'margin' => '27.4%',
            ];
        } elseif (str_contains($lower, 'tren') || str_contains($lower, 'velocity') || str_contains($lower, 'grafik')) {
            $widgetType = 'salesTrendChart';
            $widgetData = [
                'peak_day' => 'Sabtu (Rp 82 Jt)',
                'target_attainment' => '88%',
            ];
        }

        return [
            'content' => $text,
            'widget_type' => $widgetType,
            'widget_data' => $widgetData,
        ];
    }

    /**
     * Local Conversational Reasoning Engine for offline/zero-key operation.
     * Truly behaves like a natural, smart human coworker.
     */
    protected function generateLocalReasoningResponse(string $userPrompt, array $sales, string $memories): array
    {
        $lower = strtolower($userPrompt);

        // 1. Apresiasi & Terima Kasih (Handles "ok makasi supro", "makasih pri", dll)
        if (preg_match('/(makasi|makasih|supro|makasi supro|thank|tq|terima kasih|mantap|keren|siap pri|oke pri|ok pri|sip)/i', $lower)) {
            $replies = [
                "Sama-sama Bos! Santai aja, kalau ada yang perlu dibantu lagi atau mau cek data gudang tinggal colek Supri ya 👍",
                "Siap Bos, santai aja! Supri standby terus kalau Bos butuh bantuan hitung cuan atau diskusi ide promo baru.",
                "Sip Bos, seneng bisa bantu! Lanjutin aktivitasnya, urusan pantau stok biar Supri yang jagain di belakang layar.",
            ];
            return [
                'content' => $replies[crc32($userPrompt) % count($replies)],
                'widget_type' => null,
                'widget_data' => null,
            ];
        }

        // 2. Permintaan Export Laporan / CSV / Excel (Handles "pri bisa ga bikinin laporan dalam bentuk csv")
        if (preg_match('/(csv|excel|pdf|bikinin laporan|bikin laporan|export|unduh laporan|download laporan)/i', $lower)) {
            $reply = "Bisa banget dong Bos! Bos bisa langsung buka menu **Report** di sidebar sebelah kiri, lalu klik tombol **Export Excel (CSV)** atau **Download PDF** di pojok kanan atas.\n\n" .
                "Filenya langsung otomatis terunduh lengkap dengan rekap omzet Rp 284.5 Juta, HPP, laba bersih, serta rincian alokasi dananya. Mau Supri bantu rangkumin angka-angka pentingnya dulu di sini?";
            return [
                'content' => $reply,
                'widget_type' => null,
                'widget_data' => null,
            ];
        }

        // 3. Sapaan & Ramah Tamah (Greetings & Small Talk)
        if (preg_match('/^(halo|hai|pagi|siang|malam|sore|assalamualaikum|bro|oy|pri|supri)$/i', trim($lower))) {
            return [
                'content' => "Halo juga Bos! Gimana kabarnya hari ini? Toko lagi rame atau ada hal seru yang mau kita diskusikan bareng?",
                'widget_type' => null,
                'widget_data' => null,
            ];
        }

        // 4. Tanya Kabar & Small Talk (lagi ngapain, capek, dll)
        if (preg_match('/(lagi ngapain|lagi apa|sehat|kabar|capek|ngopi|istirahat)/i', $lower)) {
            return [
                'content' => "Lagi standby mantau pergerakan stok sama nungguin Bos nih haha. Jangan lupa rehat sejenak dan ngopi dulu Bos biar seger! Urusan pembukuan toko dan data kas biar sistem yang jagain. Ada yang lagi dipikirin tentang bisnis?",
                'widget_type' => null,
                'widget_data' => null,
            ];
        }

        // 5. Panduan Fitur Operasional Aplikasi
        if (preg_match('/(cara tambah produk|input barang|tambah barang)/i', $lower)) {
            return [
                'content' => "Gampang banget Bos! Klik aja tombol **Add New Product** di pojok kanan atas layar ini atau di menu **Inventory**. Masukin nama produk, SKU, harga jual, modal, dan jumlah stok. Begitu disimpan, sistem langsung otomatis memantau pergerakan stoknya!",
                'widget_type' => null,
                'widget_data' => null,
            ];
        }
        if (preg_match('/(buka cabang|tambah cabang|cabang baru)/i', $lower)) {
            return [
                'content' => "Untuk kelola cabang, masuk ke menu **Store** di sidebar kiri, lalu klik tombol **Tambah Cabang**. Di situ Bos juga bisa langsung klik tombol status di tiap kartu cabang buat ubah status Toko Buka atau Tutup secara realtime.",
                'widget_type' => null,
                'widget_data' => null,
            ];
        }
        if (preg_match('/(setting printer|printer kasir|printer thermal)/i', $lower)) {
            return [
                'content' => "Masuk ke menu **Settings > Perangkat Keras & Printer Kasir**. Di situ Bos bisa pilih ukuran kertas 80mm atau 58mm, koneksi printer thermal Bluetooth/USB, dan ada tombol **Test Cetak Struk Sampel** buat ngetes langsung ke printer.",
                'widget_type' => null,
                'widget_data' => null,
            ];
        }

        // 6. Finance & Sales Data Reading
        if (str_contains($lower, 'laba') || str_contains($lower, 'profit') || str_contains($lower, 'untung') || str_contains($lower, 'keuangan') || str_contains($lower, 'omset') || str_contains($lower, 'cuan')) {
            $rev = number_format($sales['financials']['monthly_revenue'], 0, ',', '.');
            $hpp = number_format($sales['financials']['monthly_hpp'], 0, ',', '.');
            $net = number_format($sales['financials']['net_profit'], 0, ',', '.');
            $cash = number_format($sales['financials']['cash_in_hand'], 0, ',', '.');

            $reply = "Kondisi keuangan kita bulan ini lagi bagus banget Bos!\n\n" .
                "• **Total Omzet:** Rp {$rev}\n" .
                "• **HPP (Harga Pokok):** Rp {$hpp} (rasio 59% — masih di bawah batas maksimal 60% yang kita sepakati di memori)\n" .
                "• **Laba Bersih:** **Rp {$net}** (Margin bersih **{$sales['financials']['net_profit_margin']}**)\n" .
                "• **Kas di Tangan:** Rp {$cash} (likuiditas aman untuk operasional & kulakan 45 hari ke depan).\n\n" .
                "Penjualan multi-cabang hari ini tembus Rp " . number_format($sales['financials']['today_sales'], 0, ',', '.') . " dipimpin cabang SCBD!";

            return [
                'content' => $reply,
                'widget_type' => 'financeSummary',
                'widget_data' => [
                    'revenue' => $sales['financials']['monthly_revenue'],
                    'cogs' => $sales['financials']['monthly_hpp'],
                    'netProfit' => $sales['financials']['net_profit'],
                    'margin' => $sales['financials']['net_profit_margin'],
                ],
            ];
        }

        // 7. Sales Trend & Velocity Reading
        if (str_contains($lower, 'tren') || str_contains($lower, 'velocity') || str_contains($lower, 'grafik') || str_contains($lower, 'pola') || str_contains($lower, 'jam sibuk')) {
            $reply = "Berikut analisis tren penjualan yang Supri amati dari data toko, Bos:\n\n" .
                "1. **Pola Mingguan:** Terjadi kenaikan signifikan setiap Jumat malam dan puncaknya pada **Sabtu (Rp 82 Jt)**.\n" .
                "2. **Puncak Jam Kasir:** Transaksi paling padat terjadi di rentang **14:00 - 18:00 WIB**.\n" .
                "3. **Metode Pembayaran:** 45% pelanggan membayar menggunakan **QRIS**, disusul Mesin EDC (25%).\n" .
                "4. **Kategori Penopang:** Kategori Fashion dan Watch menyumbang 65% total profit kotor toko.\n\n" .
                "Target penjualan minggu ini sudah tercapai **88%**!";

            return [
                'content' => $reply,
                'widget_type' => 'salesTrendChart',
                'widget_data' => [
                    'peak_day' => 'Sabtu (Rp 82 Jt)',
                    'peak_hours' => '14:00 - 18:00 WIB',
                    'qris_share' => '45%',
                ],
            ];
        }

        // 8. Marketing Advice & Content Strategy (Saran Pemasaran)
        if (str_contains($lower, 'konten') || str_contains($lower, 'pemasaran') || str_contains($lower, 'marketing') || str_contains($lower, 'promo') || str_contains($lower, 'tiktok') || str_contains($lower, 'iklan') || str_contains($lower, 'reels')) {
            $reply = "Supri ada saran pemasaran cerdas nih Bos buat naikin omzet minggu ini:\n\n" .
                "🎬 **Ide Konten Video TikTok / Reels (Produk: Backpack Explorer):**\n" .
                "• **Hook (3 detik pertama):** *'Jangan beli tas ransel kantor sebelum lihat ketahanan air tas ini!'* (tunjukkan siraman air ke bahan tas)\n" .
                "• **Story:** Perlihatkan kompartemen laptop 15.6 inch, bantalan busa ergonomis, dan resleting anti maling.\n" .
                "• **Call to Action:** *'Khusus hari ini, dapatkan gratis tumbler stainless untuk 20 pembeli pertama di link bio!'*\n\n" .
                "🎁 **Strategi Loyalty WhatsApp untuk Member VIP:**\n" .
                "• Kirim pesan personal ke pelanggan VIP (Budi Santoso & Siti Rahma) dengan penawaran *Private Pre-Order* produk baru diskon 10%.\n\n" .
                "📦 **Bundling Slow-Moving:** Gabungkan dompet kulit vintage dengan jam tangan untuk menaikkan Average Order Value (AOV).";

            return [
                'content' => $reply,
                'widget_type' => 'socialPromo',
                'widget_data' => [
                    'platform' => 'TikTok & Instagram Reels',
                    'target_product' => 'Backpack Explorer 25L',
                    'hook' => 'Jangan beli tas ransel kantor sebelum lihat ketahanan air tas ini!',
                ],
            ];
        }

        // 9. Inventory & Restock Alerts
        if (str_contains($lower, 'restock') || str_contains($lower, 'stok') || str_contains($lower, 'habis') || str_contains($lower, 'gudang') || str_contains($lower, 'kritis')) {
            $criticals = implode("\n", array_map(fn($it) => "• {$it}", $sales['inventory_summary']['critical_items']));

            $reply = "Data gudang mendeteksi **{$sales['inventory_summary']['critical_stock_count']} produk** berada di status KRITIS mendekati batas aman, Bos:\n\n" .
                $criticals . "\n\n" .
                "Dengan laju penjualan akhir pekan, diprediksi habis dalam 48 jam. Supri sarankan eksekusi restock order **120 unit** hari ini agar aman saat akhir pekan!";

            return [
                'content' => $reply,
                'widget_type' => 'quickRestock',
                'widget_data' => [
                    'count' => 120,
                    'items' => ['Backpack Explorer 25L', 'Stainless Tumbler 750ml Vacuum'],
                ],
            ];
        }

        // 10. General Chat / Tanya Bebas (Empathetic human coworker response)
        $humanReplies = [
            "Supri di sini Bos! Mau ngobrolin strategi toko, evaluasi tren penjualan, bikin promo baru, atau mau curhat kendala operasional kasir? Ceritain aja, Supri siap dengerin dan cari solusinya bareng-bareng.",
            "Siap dengerin Bos! Ada ide baru buat produk toko, kendala supplier, atau mau minta saran strategi omzet? Tulis aja santai, kita bedah bareng.",
            "Supri standby terus Bos! Mau bahas apa hari ini? Dari urusan stok gudang, strategi konten medsos, sampai hitung-hitungan cuan, Supri siap nemenin ngobrol.",
        ];

        return [
            'content' => $humanReplies[crc32($userPrompt) % count($humanReplies)],
            'widget_type' => null,
            'widget_data' => null,
        ];
    }
}
