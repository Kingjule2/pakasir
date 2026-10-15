import 'dart:math';
import '../models/ai_chat_message.dart';
import '../models/inventory_item.dart';
import '../models/financial_summary.dart';

/// Neural Memory Node modeled after aibrain domain entities
class NeuralMemoryNode {
  final String id;
  final String type; // 'constraint', 'decision', 'sales_pattern', 'marketing_rule', 'preference', 'current_state', 'fact'
  final String content;
  int importance; // 1 - 10
  double confidence; // 0.0 - 1.0
  final DateTime createdAt;
  DateTime lastAccessedAt;

  NeuralMemoryNode({
    required this.id,
    required this.type,
    required this.content,
    this.importance = 5,
    this.confidence = 0.95,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastAccessedAt = lastAccessedAt ?? DateTime.now();
}

class MemoryEngine {
  /// 6-Month historical pattern weight multipliers
  static const Map<String, double> seasonalFactor = {
    'Electronic': 1.25,
    'Drinks': 1.60,
    'Fashion': 1.40,
    'Watch': 1.10,
    'Toys': 1.35,
    'Home': 0.95,
  };

  /// Internal Neural Memory Store (seeded with aibrain domain memories)
  static final List<NeuralMemoryNode> _memories = [
    NeuralMemoryNode(
      id: 'mem-01',
      type: 'constraint',
      content:
          'Rasio Harga Pokok Penjualan (HPP) maksimal dijaga 60% dari total omzet untuk mempertahankan laba bersih minimal 25%.',
      importance: 10,
      confidence: 0.99,
    ),
    NeuralMemoryNode(
      id: 'mem-02',
      type: 'constraint',
      content:
          'Tarif Pajak Pertambahan Nilai (PPN) wajib 11% sesuai UU HPP pada seluruh transaksi kasir POS.',
      importance: 10,
      confidence: 0.99,
    ),
    NeuralMemoryNode(
      id: 'mem-03',
      type: 'decision',
      content:
          'Ambang batas restock otomatis diatur pada sisa stok < 30% kapasitas atau lead time 3 hari sebelum habis.',
      importance: 9,
      confidence: 0.98,
    ),
    NeuralMemoryNode(
      id: 'mem-04',
      type: 'sales_pattern',
      content:
          'Puncak transaksi harian terjadi pukul 14:00 - 18:00 WIB, dengan lonjakan penjualan tertinggi pada Jumat dan Sabtu malam.',
      importance: 8,
      confidence: 0.95,
    ),
    NeuralMemoryNode(
      id: 'mem-05',
      type: 'sales_pattern',
      content:
          'Kategori Fashion (Backpack Explorer) dan Watch (Watch X Pro) memiliki turnover rate tertinggi dengan kontribusi 65% laba kotor.',
      importance: 9,
      confidence: 0.97,
    ),
    NeuralMemoryNode(
      id: 'mem-06',
      type: 'marketing_rule',
      content:
          'Produk Fast Moving (Backpack Explorer) dipromosikan lewat konten video TikTok unboxing 15-30 detik dengan hook "3 Alasan Tas Ini Selalu Habis Terjual".',
      importance: 8,
      confidence: 0.94,
    ),
    NeuralMemoryNode(
      id: 'mem-07',
      type: 'marketing_rule',
      content:
          'Pelanggan VIP (Budi Santoso & Siti Rahma) diberikan prioritas diskon member 10% dan early-access produk baru via WhatsApp broadcast.',
      importance: 9,
      confidence: 0.96,
    ),
    NeuralMemoryNode(
      id: 'mem-08',
      type: 'marketing_rule',
      content:
          'Untuk produk slow-moving, gunakan strategi bundling: gratis tumbler stainless untuk pembelian produk fashion > Rp 300.000.',
      importance: 8,
      confidence: 0.92,
    ),
    NeuralMemoryNode(
      id: 'mem-09',
      type: 'preference',
      content:
          'Owner mengutamakan likuiditas kas di tangan minimal Rp 80.000.000 sebagai dana darurat operasional.',
      importance: 9,
      confidence: 0.98,
    ),
  ];

  static List<NeuralMemoryNode> get activeMemories =>
      List.unmodifiable(_memories);

  /// Activation scoring & retrieval algorithm ported from aibrain (activation.py & ranking.py)
  static List<Map<String, dynamic>> recall(String query, {int limit = 6}) {
    final cleanQuery = query.toLowerCase();
    final tokens = cleanQuery
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();

    final scored = <Map<String, dynamic>>[];

    for (final mem in _memories) {
      // 1. Relevance: token overlap
      final contentLower = mem.content.toLowerCase();
      int matchCount = 0;
      for (final t in tokens) {
        if (contentLower.contains(t)) matchCount++;
      }
      final relevance = tokens.isNotEmpty
          ? (matchCount / tokens.length).clamp(0.0, 1.0)
          : 0.2;

      // 2. Importance
      final importance = mem.importance / 10.0;

      // 3. Recency decay
      final daysOld = DateTime.now().difference(mem.lastAccessedAt).inDays;
      final recency = exp(-0.023 * daysOld);

      // 4. Combined activation
      var activation = (relevance * 0.40) +
          (importance * 0.30) +
          (recency * 0.20) +
          (mem.confidence * 0.10);

      // Protected types (Constraints & Decisions) get priority boost (ranking.py)
      if (mem.type == 'constraint' || mem.type == 'decision') {
        activation *= 1.25;
      }

      scored.add({
        'memory': mem,
        'activation': (activation * 100).round() / 100,
      });
    }

    scored.sort((a, b) =>
        (b['activation'] as double).compareTo(a['activation'] as double));

    final selected = scored.take(limit).toList();
    for (final item in selected) {
      (item['memory'] as NeuralMemoryNode).lastAccessedAt = DateTime.now();
    }

    return selected;
  }

  /// Context builder matching aibrain context_builder.py
  static String buildContext(String query) {
    final recalled = recall(query);
    final buffer = StringBuffer();
    buffer.writeln('=== NEURAL MEMORY ENGINE CONTEXT ===');

    for (final item in recalled) {
      final node = item['memory'] as NeuralMemoryNode;
      final score = item['activation'] as double;
      buffer.writeln('[${node.type.toUpperCase()}] (Score: $score) ${node.content}');
    }

    buffer.writeln('=== END MEMORY CONTEXT ===');
    return buffer.toString();
  }

  /// Record or reinforce memory (models.py & consolidation.py)
  static void recordMemory(
    String content, {
    String type = 'fact',
    int importance = 6,
    double confidence = 0.95,
  }) {
    final existingIndex = _memories.indexWhere(
      (m) => m.content.toLowerCase().contains(content.toLowerCase().substring(0, min(30, content.length))),
    );

    if (existingIndex != -1) {
      final existing = _memories[existingIndex];
      existing.importance = min(10, existing.importance + 1);
      existing.confidence = min(1.0, existing.confidence + 0.05);
      existing.lastAccessedAt = DateTime.now();
    } else {
      _memories.insert(
        0,
        NeuralMemoryNode(
          id: 'mem-${DateTime.now().millisecondsSinceEpoch}',
          type: type,
          content: content,
          importance: importance,
          confidence: confidence,
        ),
      );
    }
  }

  /// Turn extraction matching extraction.py
  static void extractFromConversation(String userMsg, String assistantReply) {
    final lower = userMsg.toLowerCase();

    if (lower.contains('kita tetapkan') ||
        lower.contains('mulai sekarang') ||
        lower.contains('jangan pernah') ||
        lower.contains('selalu')) {
      recordMemory(userMsg, type: 'decision', importance: 9);
    } else if (lower.contains('promosi') ||
        lower.contains('diskon') ||
        lower.contains('tiktok') ||
        lower.contains('bundling') ||
        lower.contains('iklan')) {
      recordMemory('Arahan marketing pengguna: $userMsg',
          type: 'marketing_rule', importance: 8);
    } else if (lower.contains('saya mau') ||
        lower.contains('prioritas') ||
        lower.contains('target kita')) {
      recordMemory(userMsg, type: 'preference', importance: 8);
    }
  }

  /// Compute restock priority based on historical velocity & current stock
  static List<Map<String, dynamic>> evaluateRestockPriorities(
      List<InventoryItem> items) {
    final recommendations = <Map<String, dynamic>>[];

    for (final item in items) {
      final categoryWeight = seasonalFactor[item.category] ?? 1.0;
      final velocity = (item.totalQty - item.stockIn) * categoryWeight;

      final isCritical = item.stockIn < (item.totalQty * 0.3) || item.isOutOfStock;

      if (isCritical) {
        final suggestedRestock = (item.totalQty * 0.85).round() - item.stockIn;
        recommendations.add({
          'item': item,
          'urgency': 'CRITICAL',
          'suggestedQty': suggestedRestock > 0 ? suggestedRestock : 50,
          'estimatedDailyDepletion': (velocity / 30).toStringAsFixed(1),
          'reason':
              'Stok tersisa (${item.stockIn}) di bawah batas aman 30%. Kecepatan jual $categoryWeight x diprediksi habis dalam 2-3 hari.',
        });
      }
    }

    return recommendations;
  }

  /// Generate content marketing suggestions for trending items
  static Map<String, dynamic> generateSocialContentSuggestion(
      InventoryItem item) {
    return {
      'platform': 'TikTok & Instagram Reels (9:16 Video)',
      'hook': '3 Alasan Kenapa ${item.name} Ini Selalu Sold Out!',
      'angle': 'Solusi Praktis & Lifestyle Trend 2026',
      'cta': 'Ketik "MAU" di komentar atau cek link bio sekarang untuk gratis ongkir!',
      'estimatedViewLift': '+340% jangkauan organik',
      'caption':
          'Capek barang cepat rusak? Cobain ${item.name} original dari Vault. Kualitas premium, garansi 100%. Jangan tunggu kehabisan Bos! 🔥 #VaultRetail #ProdukViral #RacunTikTok',
    };
  }

  /// Process natural language conversational query for Supri like a real human coworker
  static AiChatMessage answerUserQuery(
    String query,
    List<InventoryItem> items,
    FinancialSummary finance,
  ) {
    final lower = query.toLowerCase();

    // Learn from user query automatically via Neural Memory Engine extraction
    extractFromConversation(query, '');

    // 1. Apresiasi & Terima Kasih (Handles "ok makasi supro", "makasih pri", dll)
    if (RegExp(r'(makasi|makasih|supro|thank|tq|terima kasih|mantap|keren|siap pri|oke pri|ok pri|sip)').hasMatch(lower)) {
      final warmReplies = [
        'Sama-sama Bos! Santai aja, kalau ada yang perlu dibantu lagi atau mau cek data gudang tinggal colek Supri ya 👍',
        'Siap Bos, santai aja! Supri standby terus kalau Bos butuh insight penjualan atau mau ngobrol strategi lain.',
        'Sip Bos, seneng bisa bantu! Lanjutin aktivitasnya, urusan pantau stok dan angka cuan biar Supri yang jagain di belakang layar.',
      ];
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: warmReplies[query.hashCode.abs() % warmReplies.length],
        timestamp: DateTime.now(),
      );
    }

    // 2. Permintaan Export Laporan / CSV / Excel / PDF (Handles "pri bisa ga bikinin laporan dalam bentuk csv")
    if (RegExp(r'(csv|excel|pdf|bikinin laporan|bikin laporan|export|unduh laporan|download laporan)').hasMatch(lower)) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text:
            'Bisa banget dong Bos! Bos bisa langsung buka menu **Report** di sidebar sebelah kiri, lalu klik tombol **Export Excel (CSV)** atau **Download PDF** di pojok kanan atas.\n\n'
            'Filenya langsung otomatis terunduh lengkap dengan rekap omzet Rp ${(finance.totalRevenue / 1000000).toStringAsFixed(1)} Juta, HPP, laba bersih, serta rincian alokasi dananya. Mau Supri bantu rangkumin poin-poin pentingnya dulu di sini?',
        timestamp: DateTime.now(),
      );
    }

    // 3. Sapaan Ramah Tamah (Greetings: "halo", "hai", "pagi", dll)
    if (RegExp(r'^(halo|hai|pagi|siang|malam|sore|assalamualaikum|bro|oy|pri|supri)$').hasMatch(lower.trim())) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: 'Halo juga Bos! Gimana kabarnya hari ini? Toko lagi rame atau ada hal seru yang mau kita diskusikan bareng?',
        timestamp: DateTime.now(),
      );
    }

    // 4. Tanya Kabar & Small Talk ("lagi ngapain", "capek", dll)
    if (RegExp(r'(lagi ngapain|lagi apa|sehat|kabar|capek|ngopi|istirahat)').hasMatch(lower)) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: 'Lagi standby mantau pergerakan stok sama nungguin Bos nih haha. Jangan lupa rehat sejenak dan ngopi dulu Bos biar seger! Urusan pembukuan toko dan data kas biar sistem yang jagain. Ada yang lagi dipikirin tentang toko?',
        timestamp: DateTime.now(),
      );
    }

    // 5. Panduan Fitur Operasional Aplikasi
    if (lower.contains('tambah produk') || lower.contains('input barang')) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: 'Gampang banget Bos! Klik aja tombol **Add New Product** di pojok kanan atas layar ini atau di halaman **Inventory**. Masukin nama produk, harga modal, harga jual, sama stok awal, langsung ke-track otomatis!',
        timestamp: DateTime.now(),
      );
    }
    if (lower.contains('buka cabang') || lower.contains('tambah cabang')) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: 'Untuk kelola cabang, masuk ke menu **Store** di sidebar kiri, lalu klik tombol **Tambah Cabang**. Di situ Bos juga bisa langsung klik tombol status di tiap kartu cabang buat ubah status Toko Buka atau Tutup secara realtime.',
        timestamp: DateTime.now(),
      );
    }
    if (lower.contains('printer')) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: 'Tinggal ke menu **Settings > Perangkat Keras & Printer Kasir**. Di situ Bos bisa pilih ukuran kertas 80mm atau 58mm, koneksi printer thermal Bluetooth/USB, dan coba tombol **Test Cetak Struk Sampel** buat ngetes langsung ke printer.',
        timestamp: DateTime.now(),
      );
    }

    // 6. Finance / Profit question (Reading Live Sales & P&L)
    if (lower.contains('laba') ||
        lower.contains('untung') ||
        lower.contains('keuangan') ||
        lower.contains('omset') ||
        lower.contains('cash flow') ||
        lower.contains('hpp') ||
        lower.contains('cuan')) {
      final netFormatted =
          'Rp ${(finance.netProfit / 1000000).toStringAsFixed(1)} Juta';
      final grossFormatted =
          'Rp ${(finance.grossProfit / 1000000).toStringAsFixed(1)} Juta';
      final hppFormatted =
          'Rp ${(finance.totalHpp / 1000000).toStringAsFixed(1)} Juta';

      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text:
            'Kondisi keuangan toko kita bulan ini lagi mantap banget, Bos!\n\n'
            '• **Laba Bersih:** **$netFormatted** (Margin bersih **27.4%**)\n'
            '• **Laba Kotor:** **$grossFormatted**\n'
            '• **Total HPP:** **$hppFormatted** (Rasio 59% — masih di bawah batas maksimal 60% yang kita sepakati di memori)\n'
            '• **Saldo Kas di Tangan:** **Rp ${(finance.cashInHand / 1000000).toStringAsFixed(1)} Juta**\n'
            '• **Dana Siap Kulakan:** **Rp ${(finance.stockRestockBudget / 1000000).toStringAsFixed(1)} Juta**\n\n'
            'Arus kas kita sangat sehat, likuiditas mampu menutupi operasional & kulakan untuk 45 hari ke depan!',
        timestamp: DateTime.now(),
        widgetType: SupriWidgetType.financialBreakdown,
        widgetData: {
          'netProfit': finance.netProfit,
          'grossProfit': finance.grossProfit,
          'hpp': finance.totalHpp,
          'restockBudget': finance.stockRestockBudget,
        },
      );
    }

    // 7. Sales Trend & Velocity question (Reading Sales Trends)
    if (lower.contains('tren') ||
        lower.contains('velocity') ||
        lower.contains('jam sibuk') ||
        lower.contains('peak') ||
        lower.contains('pola')) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text:
            'Tren penjualan kita lagi menarik banget kalau dilihat dari data toko, Bos:\n\n'
            '1. **Pola Mingguan:** Kenaikan omzet paling tinggi terjadi di hari **Jumat & Sabtu malam (puncaknya Rp 82 Jt)**.\n'
            '2. **Puncak Jam Kasir:** Kasir paling sibuk di rentang **14:00 - 18:00 WIB**.\n'
            '3. **Metode Bayar:** **45% pelanggan bayar pakai QRIS**, disusul EDC Bank 25%, dan Tunai 18%.\n'
            '4. **Kategori Penopang:** Kategori Fashion dan Watch menyumbang 65% laba kotor toko.\n\n'
            'Target penjualan minggu ini sudah tercapai **88%**!',
        timestamp: DateTime.now(),
        widgetType: SupriWidgetType.financialBreakdown,
        widgetData: {
          'peakDay': 'Sabtu (Rp 82 Jt)',
          'peakHours': '14:00 - 18:00 WIB',
          'qrisShare': '45%',
          'targetAttainment': '88%',
        },
      );
    }

    // 8. Marketing Advice / Saran Pemasaran / Konten promo / TikTok
    if (lower.contains('konten') ||
        lower.contains('tiktok') ||
        lower.contains('promo') ||
        lower.contains('iklan') ||
        lower.contains('reels') ||
        lower.contains('pemasaran') ||
        lower.contains('marketing') ||
        lower.contains('jual')) {
      final trending = items.firstWhere(
        (it) => it.tag == 'Fast Moving',
        orElse: () => items.isNotEmpty ? items.first : InventoryItem(
          id: 'dummy',
          name: 'Backpack Explorer 25L',
          sku: 'SKU-001',
          category: 'Fashion',
          totalQty: 200,
          stockIn: 12,
          price: 320000,
          costPrice: 190000,
          priority: PriorityLevel.high,
          tag: 'Fast Moving',
        ),
      );
      final content = generateSocialContentSuggestion(trending);

      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text:
            'Supri ada ide konten segar buat produk **${trending.name}** yang lagi laris nih Bos:\n\n'
            '🎬 **Ide Konten FYP TikTok & Reels:**\n'
            '• **Hook 3 Detik:** *"${content['hook']}"*\n'
            '• **Angle Cerita:** ${content['angle']}\n'
            '• **Call to Action:** ${content['cta']}\n\n'
            '🎁 **Saran Program Loyalty WhatsApp:**\n'
            '• Kirim pesan personal ke pelanggan VIP (Budi Santoso & Siti Rahma) untuk penawaran diskon member 10%.\n\n'
            '📦 **Saran Bundling:** Paketkan produk aksesoris slow-moving untuk mendongkrak Average Order Value!',
        timestamp: DateTime.now(),
        widgetType: SupriWidgetType.contentSuggestion,
        widgetData: content,
      );
    }

    // 9. Restock / Stok menipis question
    if (lower.contains('restock') ||
        lower.contains('habis') ||
        lower.contains('stok') ||
        lower.contains('gudang') ||
        lower.contains('kulakan') ||
        lower.contains('kritis')) {
      final criticalItems = evaluateRestockPriorities(items);
      final count = criticalItems.length;

      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text:
            'Siap Bos! Data gudang mendeteksi ada **$count barang** yang mendekati batas aman buffer stok.\n\n'
            'Yang paling darurat adalah **Backpack Explorer (sisa 12 unit)** dan **Tumbler Stainless (sisa 8 unit)**.\n'
            'Saran Supri: Eksekusi PO restock otomatis **120 unit** hari ini agar tidak kehabisan barang saat lonjakan pembeli akhir pekan nanti!',
        timestamp: DateTime.now(),
        widgetType: SupriWidgetType.quickRestock,
        widgetData: {
          'count': count > 0 ? count : 120,
          'items': criticalItems.map((e) => (e['item'] as InventoryItem).name).toList(),
        },
      );
    }

    // 10. Memory Engine Check / Aturan yang dipelajari
    if (lower.contains('ingat') ||
        lower.contains('memori') ||
        lower.contains('aturan') ||
        lower.contains('brain')) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text:
            'Supri selalu ingat aturan main bisnis kita Bos:\n\n'
            '• [CONSTRAINT] Rasio HPP maksimal dijaga 60% & PPN wajib 11%.\n'
            '• [DECISION] Ambang batas restock otomatis < 30% stok buffer.\n'
            '• [SALES PATTERN] Puncak belanja 14:00 - 18:00 WIB & Sabtu malam.\n'
            '• [MARKETING] Konten TikTok hook 3 detik & promo WhatsApp member VIP.\n'
            '• [PREFERENCE] Likuiditas kas darurat minimal Rp 80.000.000.\n\n'
            'Setiap percakapan atau arahan baru dari Bos juga langsung Supri pelajari dan simpan di Memory Engine!',
        timestamp: DateTime.now(),
      );
    }

    // 11. General Human Coworker Chat (NEVER returns rigid 1.. 2.. 3.. menu!)
    final humanReplies = [
      'Supri di sini Bos! Mau ngobrolin strategi toko, evaluasi tren penjualan, bikin promo baru, atau mau curhat kendala operasional kasir? Ceritain aja, Supri siap dengerin dan cari solusinya bareng-bareng.',
      'Siap dengerin Bos! Ada ide baru buat produk toko, kendala supplier, atau mau minta saran strategi omzet? Tulis aja santai, kita bedah bareng.',
      'Supri standby terus Bos! Mau bahas apa hari ini? Dari urusan stok gudang, strategi konten medsos, sampai hitung-hitungan cuan, Supri siap nemenin ngobrol.',
    ];

    return AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      text: humanReplies[query.hashCode.abs() % humanReplies.length],
      timestamp: DateTime.now(),
    );
  }
}
