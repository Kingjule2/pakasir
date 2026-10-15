<?php

namespace Database\Seeders;

use App\Models\AiConversation;
use App\Models\AiInsight;
use App\Models\AiMessage;
use App\Models\AiRecommendation;
use App\Models\Business;
use App\Models\Category;
use App\Models\Customer;
use App\Models\Faq;
use App\Models\Memory;
use App\Models\Product;
use App\Models\SalesAnalytic;
use App\Models\SecurityAuditLog;
use App\Models\StoreOutlet;
use App\Models\StoreSetting;
use App\Models\SupportTicket;
use App\Models\Transaction;
use App\Models\TransactionItem;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Users
        $admin = User::create([
            'name' => 'Evano (Sales Admin)',
            'email' => 'admin@vault-retail.id',
            'password' => Hash::make('password123'),
            'role' => 'superadmin',
            'api_token' => 'vault-demo-token-12345',
        ]);

        $manager = User::create([
            'name' => 'Maya Safitri',
            'email' => 'maya@vault-retail.id',
            'password' => Hash::make('password123'),
            'role' => 'manager',
            'api_token' => 'vault-manager-token-67890',
        ]);

        $cashier = User::create([
            'name' => 'Siti Rahma',
            'email' => 'siti@vault-retail.id',
            'password' => Hash::make('password123'),
            'role' => 'cashier',
            'api_token' => 'vault-cashier-token-11223',
        ]);

        // 2. Business
        $business = Business::create([
            'owner_id' => $admin->id,
            'business_name' => 'Vault Retail & Lifestyle',
            'business_type' => 'Fashion & Smart Retail',
            'address' => 'SCBD Lot 8, Jl. Jend. Sudirman Kav. 52, Jakarta Selatan',
            'phone' => '+62 821-8899-7766',
            'currency' => 'IDR',
        ]);

        // 3. Settings
        StoreSetting::create([
            'business_id' => $business->id,
            'store_name' => 'Vault Retail & Lifestyle',
            'store_tagline' => 'SaaS Smart Inventory & POS Management',
            'email' => 'owner@vault-retail.id',
            'phone' => '+62 821-8899-7766',
            'address' => 'Jl. Jenderal Sudirman No. 52, SCBD Jakarta Selatan 12190',
            'currency_symbol' => 'Rp',
            'currency_code' => 'IDR',
            'tax_rate' => 11.00,
            'tax_enabled' => true,
            'service_fee_rate' => 5.00,
            'service_fee_enabled' => false,
            'printer_name' => 'Epson TM-T82X (Thermal)',
            'paper_width' => '80mm',
            'auto_print_receipt' => true,
            'sound_alerts' => true,
            'low_stock_threshold' => 20,
            'low_stock_notification' => true,
            'daily_report_email' => true,
            'two_factor_auth_enabled' => true,
            'biometric_login_enabled' => true,
            'customer_data_anonymized' => false,
            'language' => 'Bahasa Indonesia',
        ]);

        // 4. Categories
        $catFashion = Category::create(['business_id' => $business->id, 'name' => 'Fashion', 'slug' => 'fashion']);
        $catWatch = Category::create(['business_id' => $business->id, 'name' => 'Watch', 'slug' => 'watch']);
        $catBottles = Category::create(['business_id' => $business->id, 'name' => 'Bottles', 'slug' => 'bottles']);
        $catElectronic = Category::create(['business_id' => $business->id, 'name' => 'Electronic', 'slug' => 'electronic']);
        $catAccessories = Category::create(['business_id' => $business->id, 'name' => 'Accessories', 'slug' => 'accessories']);

        // 5. Products
        $p1 = Product::create([
            'business_id' => $business->id,
            'category_id' => $catFashion->id,
            'name' => 'Backpack Explorer 25L',
            'sku' => 'SKU-001',
            'description' => 'Tas ransel outdoor bahan Cordura anti air.',
            'category' => 'Fashion',
            'price' => 320000,
            'cost_price' => 190000,
            'total_qty' => 200,
            'stock_in' => 12, // Critical low stock
            'priority' => 'high',
            'tag' => 'Fast Moving',
            'image_asset' => 'backpack',
            'is_out_of_stock' => false,
        ]);

        $p2 = Product::create([
            'business_id' => $business->id,
            'category_id' => $catWatch->id,
            'name' => 'Smart Watch X Pro Steel',
            'sku' => 'SKU-002',
            'description' => 'Jam tangan pintar layar AMOLED dengan sensor detak jantung.',
            'category' => 'Watch',
            'price' => 650000,
            'cost_price' => 420000,
            'total_qty' => 150,
            'stock_in' => 45,
            'priority' => 'medium',
            'tag' => 'Fast Moving',
            'image_asset' => 'watch',
            'is_out_of_stock' => false,
        ]);

        $p3 = Product::create([
            'business_id' => $business->id,
            'category_id' => $catBottles->id,
            'name' => 'Stainless Tumbler 750ml Vacuum',
            'sku' => 'SKU-003',
            'description' => 'Botol minum insulasi suhu tahan panas 12 jam.',
            'category' => 'Bottles',
            'price' => 125000,
            'cost_price' => 70000,
            'total_qty' => 300,
            'stock_in' => 8, // Critical low stock
            'priority' => 'high',
            'tag' => 'Fast Moving',
            'image_asset' => 'bottle',
            'is_out_of_stock' => false,
        ]);

        $p4 = Product::create([
            'business_id' => $business->id,
            'category_id' => $catElectronic->id,
            'name' => 'Wireless Earbuds ANC Pro',
            'sku' => 'SKU-004',
            'description' => 'TWS Bluetooth 5.3 dengan Active Noise Cancellation.',
            'category' => 'Electronic',
            'price' => 450000,
            'cost_price' => 260000,
            'total_qty' => 100,
            'stock_in' => 60,
            'priority' => 'low',
            'tag' => 'New Arrival',
            'image_asset' => 'earbuds',
            'is_out_of_stock' => false,
        ]);

        $p5 = Product::create([
            'business_id' => $business->id,
            'category_id' => $catAccessories->id,
            'name' => 'Leather Wallet Vintage RFID',
            'sku' => 'SKU-005',
            'description' => 'Dompet kulit sapi asli proteksi RFID skimming.',
            'category' => 'Accessories',
            'price' => 180000,
            'cost_price' => 95000,
            'total_qty' => 80,
            'stock_in' => 40,
            'priority' => 'low',
            'tag' => 'Regular',
            'image_asset' => 'wallet',
            'is_out_of_stock' => false,
        ]);

        $p6 = Product::create([
            'business_id' => $business->id,
            'category_id' => $catAccessories->id,
            'name' => 'Polarized Sunglasses Classic',
            'sku' => 'SKU-006',
            'description' => 'Kacamata hitam polarized UV400 frame titanium.',
            'category' => 'Accessories',
            'price' => 140000,
            'cost_price' => 75000,
            'total_qty' => 120,
            'stock_in' => 15,
            'priority' => 'medium',
            'tag' => 'Fast Moving',
            'image_asset' => 'glasses',
            'is_out_of_stock' => false,
        ]);

        // 6. Customers
        $c1 = Customer::create([
            'business_id' => $business->id,
            'name' => 'Budi Santoso',
            'email' => 'budi.santoso@gmail.com',
            'phone' => '+62 812-4455-6677',
            'tier' => 'VIP',
            'total_orders' => 38,
            'total_spent' => 45200000,
            'city' => 'Jakarta Selatan',
            'last_active' => 'Hari ini, 14:20',
            'status' => 'Aktif',
            'notes' => 'Pelanggan loyal kategori Fashion & Jam Tangan.',
        ]);

        $c2 = Customer::create([
            'business_id' => $business->id,
            'name' => 'Siti Rahmawati',
            'email' => 'siti.rahma@outlook.com',
            'phone' => '+62 813-8899-1122',
            'tier' => 'VIP',
            'total_orders' => 26,
            'total_spent' => 32800000,
            'city' => 'Bandung',
            'last_active' => 'Kemarin, 16:45',
            'status' => 'Aktif',
            'notes' => 'Prioritas diskon member VIP 10%.',
        ]);

        $c3 = Customer::create([
            'business_id' => $business->id,
            'name' => 'CV Berkah Perkasa',
            'email' => 'procurement@berkahperkasa.co.id',
            'phone' => '+62 811-9900-3344',
            'tier' => 'Wholesale',
            'total_orders' => 54,
            'total_spent' => 85000000,
            'city' => 'Semarang',
            'last_active' => 'Hari ini, 10:15',
            'status' => 'Aktif',
            'notes' => 'Pembelian grosir botol tumbler tempo 14 hari.',
        ]);

        Customer::create([
            'business_id' => $business->id,
            'name' => 'Ahmad Fauzi',
            'email' => 'ahmad.fauzi@yahoo.com',
            'phone' => '+62 856-7788-9900',
            'tier' => 'Regular',
            'total_orders' => 14,
            'total_spent' => 12500000,
            'city' => 'Surabaya',
            'last_active' => '2 hari lalu',
            'status' => 'Aktif',
        ]);

        Customer::create([
            'business_id' => $business->id,
            'name' => 'Dewi Lestari',
            'email' => 'dewi.lestari@gmail.com',
            'phone' => '+62 878-1122-4455',
            'tier' => 'Regular',
            'total_orders' => 9,
            'total_spent' => 8750000,
            'city' => 'Yogyakarta',
            'last_active' => '5 hari lalu',
            'status' => 'Aktif',
        ]);

        Customer::create([
            'business_id' => $business->id,
            'name' => 'Hendrik Wijaya',
            'email' => 'hendrik.w@gmail.com',
            'phone' => '+62 822-3344-5566',
            'tier' => 'Baru',
            'total_orders' => 2,
            'total_spent' => 1450000,
            'city' => 'Denpasar',
            'last_active' => 'Hari ini, 11:05',
            'status' => 'Aktif',
        ]);

        // 7. Store Outlets
        $outScbd = StoreOutlet::create([
            'business_id' => $business->id,
            'name' => 'Vault Central SCBD (Flagship)',
            'code' => 'JKT-01',
            'city' => 'Jakarta Selatan',
            'address' => 'SCBD Lot 8, Jl. Jend. Sudirman Kav. 52-53',
            'manager' => 'Andi Pratama',
            'phone' => '+62 812-1111-2222',
            'operating_hours' => '09:00 - 22:00 WIB',
            'is_open' => true,
            'terminals_count' => 4,
            'daily_sales' => 18450000,
            'monthly_sales' => 112000000,
            'staff_count' => 8,
        ]);

        $outPvj = StoreOutlet::create([
            'business_id' => $business->id,
            'name' => 'Vault Hub Paris Van Java',
            'code' => 'BDG-02',
            'city' => 'Bandung',
            'address' => 'PVJ Mall GF-12, Jl. Sukajadi No. 137',
            'manager' => 'Maya Safitri',
            'phone' => '+62 813-3333-4444',
            'operating_hours' => '10:00 - 22:00 WIB',
            'is_open' => true,
            'terminals_count' => 3,
            'daily_sales' => 12200000,
            'monthly_sales' => 78500000,
            'staff_count' => 5,
        ]);

        $outSby = StoreOutlet::create([
            'business_id' => $business->id,
            'name' => 'Vault Express Tunjungan',
            'code' => 'SBY-03',
            'city' => 'Surabaya',
            'address' => 'Tunjungan Plaza 4 Lt. 2 No. 45',
            'manager' => 'Bambang Irawan',
            'phone' => '+62 811-5555-6666',
            'operating_hours' => '10:00 - 21:30 WIB',
            'is_open' => true,
            'terminals_count' => 2,
            'daily_sales' => 9800000,
            'monthly_sales' => 54000000,
            'staff_count' => 4,
        ]);

        StoreOutlet::create([
            'business_id' => $business->id,
            'name' => 'Vault Store Seminyak',
            'code' => 'DPS-04',
            'city' => 'Bali',
            'address' => 'Jl. Kayu Aya No. 88, Seminyak, Kuta',
            'manager' => 'Putu Dharma',
            'phone' => '+62 819-7777-8888',
            'operating_hours' => '11:00 - 23:00 WITA',
            'is_open' => false,
            'terminals_count' => 2,
            'daily_sales' => 6500000,
            'monthly_sales' => 40000000,
            'staff_count' => 3,
        ]);

        // 8. Transactions
        $t1 = Transaction::create([
            'business_id' => $business->id,
            'store_outlet_id' => $outScbd->id,
            'customer_id' => $c1->id,
            'invoice_number' => 'INV-20261013-0001',
            'subtotal' => 970000,
            'discount' => 50000,
            'tax_amount' => 101200,
            'service_fee' => 0,
            'total_amount' => 1021200,
            'payment_method' => 'QRIS',
            'payment_status' => 'paid',
            'transaction_date' => Carbon::now()->subMinutes(15),
        ]);

        TransactionItem::create([
            'transaction_id' => $t1->id,
            'product_id' => $p1->id,
            'product_name' => $p1->name,
            'quantity' => 1,
            'unit_price' => 320000,
            'cost_price' => 190000,
            'subtotal' => 320000,
        ]);

        TransactionItem::create([
            'transaction_id' => $t1->id,
            'product_id' => $p2->id,
            'product_name' => $p2->name,
            'quantity' => 1,
            'unit_price' => 650000,
            'cost_price' => 420000,
            'subtotal' => 650000,
        ]);

        $t2 = Transaction::create([
            'business_id' => $business->id,
            'store_outlet_id' => $outPvj->id,
            'customer_id' => $c2->id,
            'invoice_number' => 'INV-20261013-0002',
            'subtotal' => 250000,
            'discount' => 0,
            'tax_amount' => 27500,
            'service_fee' => 0,
            'total_amount' => 277500,
            'payment_method' => 'EDC BCA',
            'payment_status' => 'paid',
            'transaction_date' => Carbon::now()->subHours(1),
        ]);

        TransactionItem::create([
            'transaction_id' => $t2->id,
            'product_id' => $p3->id,
            'product_name' => $p3->name,
            'quantity' => 2,
            'unit_price' => 125000,
            'cost_price' => 70000,
            'subtotal' => 250000,
        ]);

        // 9. Sales Analytics (Last 7 Days)
        $days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        $revs = [32000000, 41000000, 38000000, 52000000, 68000000, 82000000, 61000000];
        $profits = [8600000, 11200000, 10400000, 14200000, 18500000, 22400000, 16800000];

        foreach ($days as $idx => $d) {
            SalesAnalytic::create([
                'business_id' => $business->id,
                'analysis_date' => Carbon::now()->subDays(6 - $idx)->format('Y-m-d'),
                'total_quantity' => 120 + $idx * 15,
                'total_revenue' => $revs[$idx],
                'total_profit' => $profits[$idx],
                'sales_growth' => 12.5 + $idx * 1.2,
                'performance_status' => $idx >= 4 ? 'Excellent' : 'Good',
            ]);
        }

        // 10. AI Supri Conversation & Messages
        $convo = AiConversation::create([
            'user_id' => $admin->id,
            'business_id' => $business->id,
            'title' => 'Asisten Inventaris & Keuangan Supri',
        ]);

        AiMessage::create([
            'conversation_id' => $convo->id,
            'role' => 'assistant',
            'content' => "Halo Bos! Saya **Supri**, AI Inventory & Finance Coworker kamu.\n\nMemory Engine mendeteksi **120 produk** perlu segera di-restock sebelum akhir pekan.",
            'widget_type' => 'quickRestock',
            'widget_data' => [
                'count' => 120,
                'items' => ['Backpack Explorer 25L', 'Stainless Tumbler 750ml Vacuum'],
            ],
        ]);

        // 11. Memories
        Memory::create([
            'user_id' => $admin->id,
            'business_id' => $business->id,
            'memory_type' => 'restock_rule',
            'content' => 'Batas kritis restock otomatis diatur pada sisa stok < 30% dari total unit kapasitas gudang.',
            'confidence_score' => 0.98,
            'importance_score' => 9,
            'last_accessed_at' => Carbon::now(),
        ]);

        Memory::create([
            'user_id' => $admin->id,
            'business_id' => $business->id,
            'memory_type' => 'finance_pattern',
            'content' => 'Rasio HPP toko dipertahankan di bawah 60% untuk menjaga net profit margin di atas 25%.',
            'confidence_score' => 0.95,
            'importance_score' => 8,
            'last_accessed_at' => Carbon::now(),
        ]);

        // 12. AI Insights & Recommendations
        $insight = AiInsight::create([
            'business_id' => $business->id,
            'insight_type' => 'restock',
            'title' => 'Stok Kritis Backpack & Tumbler Menjelang Akhir Pekan',
            'description' => 'Laju penjualan meningkat 18% pada hari Jumat dan Sabtu. Stok saat ini diperkirakan habis dalam 48 jam.',
            'confidence_score' => 0.94,
            'supporting_data' => ['depletion_days' => 2, 'recommended_units' => 120],
        ]);

        AiRecommendation::create([
            'business_id' => $business->id,
            'insight_id' => $insight->id,
            'recommendation_type' => 'restock_order',
            'recommendation' => 'Pesan 80 unit Backpack Explorer dan 40 unit Stainless Tumbler ke Supplier Resmi.',
            'status' => 'pending',
        ]);

        // 13. Security Audit Logs
        SecurityAuditLog::create([
            'user' => 'Evano (Sales Admin)',
            'role' => 'Superadmin',
            'action' => 'Restock Otomatis 120 Unit via Supri AI',
            'target' => 'Inventory Database',
            'ip_address' => '192.168.1.10',
            'status' => 'Sukses',
        ]);

        SecurityAuditLog::create([
            'user' => 'Evano (Sales Admin)',
            'role' => 'Superadmin',
            'action' => 'Penyesuaian Tarif Pajak PPN 11%',
            'target' => 'Billing Settings',
            'ip_address' => '192.168.1.10',
            'status' => 'Sukses',
        ]);

        SecurityAuditLog::create([
            'user' => 'Siti (Kasir PVJ)',
            'role' => 'Kasir POS',
            'action' => 'Void Transaksi #ORD-8812 (Pelanggan Ganti Pesanan)',
            'target' => 'POS Terminal 2',
            'ip_address' => '192.168.1.42',
            'status' => 'Peringatan',
        ]);

        SecurityAuditLog::create([
            'user' => 'Unknown Actor',
            'role' => 'Guest / External',
            'action' => 'Percobaan Brute Force Login 5x Gagal',
            'target' => 'Auth Gateway',
            'ip_address' => '103.45.12.89',
            'status' => 'Diblokir',
        ]);

        SecurityAuditLog::create([
            'user' => 'Maya Safitri',
            'role' => 'Store Manager',
            'action' => 'Ekspor Rekap Laporan Penjualan Mingguan',
            'target' => 'Reports Export',
            'ip_address' => '192.168.1.18',
            'status' => 'Sukses',
        ]);

        // 14. FAQs & Support Tickets
        Faq::create([
            'category' => 'Inventaris & Stok',
            'question' => 'Bagaimana cara AI Memory Engine menghitung rekomendasi restock?',
            'answer' => 'Memory Engine melacak laju penjualan (turnover rate) dan waktu tunggu pengiriman (lead time) supplier selama 6 bulan terakhir. Jika sisa stok diperkirakan habis dalam 3 hari ke depan, sistem otomatis menaikkan status menjadi "CRITICAL" dan menyarankan jumlah restock optimal.',
        ]);

        Faq::create([
            'category' => 'AI Supri Assistant',
            'question' => 'Apa saja perintah suara / teks yang dapat dipahami Supri AI?',
            'answer' => 'Supri dapat menganalisis laba bersih mingguan, mendeteksi produk slow-moving, mengeksekusi order restock satu klik, memberikan ide konten viral TikTok untuk produk tertentu, dan menjawab status pengiriman supplier.',
        ]);

        Faq::create([
            'category' => 'Kasir & POS',
            'question' => 'Apakah aplikasi dapat beroperasi jika koneksi internet terputus (Offline)?',
            'answer' => 'Ya, aplikasi dilengkapi mode Local Cache. Transaksi kasir tetap tersimpan di memori perangkat dan akan otomatis disinkronkan ke cloud saat koneksi internet kembali stabil.',
        ]);

        Faq::create([
            'category' => 'Pajak & Laporan',
            'question' => 'Bagaimana mengatur tarif PPN 11% dan mencetak laporan resmi?',
            'answer' => 'Buka menu Settings > Pajak & Biaya, aktifkan toggle PPN dan tentukan tarif 11%. Anda dapat mengunduh rekap faktur penjualan format PDF atau Excel melalui menu Report kapan saja.',
        ]);

        Faq::create([
            'category' => 'Perangkat & Printer',
            'question' => 'Printer kasir apa saja yang didukung oleh Vault?',
            'answer' => 'Mendukung printer thermal ukuran 58mm dan 80mm via koneksi Bluetooth, USB, maupun Ethernet LAN (seperti Epson, Panda, Iware, Xprinter).',
        ]);

        SupportTicket::create([
            'ticket_code' => 'TCK-2026-091',
            'subject' => 'Permintaan Integrasi Mesin EDC BCA ke Kasir Terminal 1',
            'category' => 'Hardware & EDC',
            'status' => 'Diproses',
            'priority' => 'Sedang',
            'message' => 'Integrasi API webhook EDC BCA untuk verifikasi settlement otomatis.',
        ]);

        SupportTicket::create([
            'ticket_code' => 'TCK-2026-088',
            'subject' => 'Sinkronisasi Stok Cabang Seminyak saat Pemadaman Listrik',
            'category' => 'Sinkronisasi Data',
            'status' => 'Selesai',
            'priority' => 'Tinggi',
            'message' => 'Validasi cache offline dan penyesuaian delta stock opname.',
        ]);
    }
}
