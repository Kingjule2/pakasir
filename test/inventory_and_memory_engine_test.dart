import 'package:flutter_test/flutter_test.dart';
import 'package:pakasir2/models/ai_chat_message.dart';
import 'package:pakasir2/models/financial_summary.dart';
import 'package:pakasir2/models/inventory_item.dart';
import 'package:pakasir2/services/inventory_store.dart';
import 'package:pakasir2/services/memory_engine.dart';

void main() {
  group('Memory Engine & Inventory Store Tests', () {
    test('MemoryEngine detects restock priority for low stock items', () {
      final items = [
        InventoryItem(
          id: 'test-1',
          name: 'Backpack',
          sku: 'SKU-001',
          category: 'Fashion',
          totalQty: 200,
          stockIn: 10, // critical low stock
          price: 100,
          costPrice: 60,
          priority: PriorityLevel.high,
          tag: 'Fast Moving',
        ),
        InventoryItem(
          id: 'test-2',
          name: 'Watch X',
          sku: 'SKU-002',
          category: 'Watch',
          totalQty: 500,
          stockIn: 450, // plenty of stock
          price: 200,
          costPrice: 120,
          priority: PriorityLevel.low,
          tag: 'New Arrival',
        ),
      ];

      final restocks = MemoryEngine.evaluateRestockPriorities(items);
      expect(restocks.isNotEmpty, isTrue);
      expect((restocks.first['item'] as InventoryItem).name, equals('Backpack'));
      expect(restocks.first['urgency'], equals('CRITICAL'));
    });

    test('MemoryEngine answers conversational finance questions', () {
      final items = <InventoryItem>[];
      final finance = FinancialSummary.demo();

      final answer = MemoryEngine.answerUserQuery(
        'Berapa laba bersih minggu ini?',
        items,
        finance,
      );

      expect(answer.text.contains('Laba Bersih'), isTrue);
      expect(answer.widgetData?['netProfit'], isNotNull);
    });

    test('MemoryEngine generates social media content suggestions', () {
      final item = InventoryItem(
        id: 'test-3',
        name: 'Headphones Pro',
        sku: 'SKU-999',
        category: 'Electronic',
        totalQty: 100,
        stockIn: 80,
        price: 250,
        costPrice: 150,
        priority: PriorityLevel.high,
        tag: 'Fast Moving',
      );

      final suggestion = MemoryEngine.generateSocialContentSuggestion(item);
      expect(suggestion['platform'], contains('TikTok'));
      expect(suggestion['hook'], contains('Headphones Pro'));
    });

    test('InventoryStore executes one-click restock properly', () {
      final store = InventoryStore();
      final outOfStockCountBefore =
          store.allItems.where((i) => i.isOutOfStock || i.stockIn < 30).length;
      expect(outOfStockCountBefore, greaterThan(0));

      store.executeAllRecommendedRestock();

      final outOfStockCountAfter =
          store.allItems.where((i) => i.isOutOfStock).length;
      expect(outOfStockCountAfter, equals(0));
    });

    test('Neural Memory Engine recalls memories and builds structured context', () {
      final recalled = MemoryEngine.recall('aturan rasio hpp dan batas restock');
      expect(recalled.isNotEmpty, isTrue);
      expect(recalled.first['activation'], greaterThan(0));

      final context = MemoryEngine.buildContext('promosi tiktok produk fast moving');
      expect(context.contains('NEURAL MEMORY ENGINE CONTEXT'), isTrue);
      expect(context.contains('MARKETING_RULE') || context.contains('CONSTRAINT'), isTrue);
    });

    test('Neural Memory Engine answers sales trend and marketing questions', () {
      final items = <InventoryItem>[];
      final finance = FinancialSummary.demo();

      // Sales Trend query
      final trendAnswer = MemoryEngine.answerUserQuery(
        'Bagaimana analisis tren penjualan dan jam sibuk kasir?',
        items,
        finance,
      );
      expect(trendAnswer.text.contains('Puncak Jam Kasir') || trendAnswer.text.contains('Tren Penjualan'), isTrue);
      expect(trendAnswer.text.contains('QRIS'), isTrue);

      // Marketing Advice query
      final marketingAnswer = MemoryEngine.answerUserQuery(
        'Kasih ide konten TikTok dan saran pemasaran produk terlaris!',
        items,
        finance,
      );
      expect(marketingAnswer.text.contains('TikTok') || marketingAnswer.text.contains('Hook'), isTrue);
      expect(marketingAnswer.widgetType, equals(SupriWidgetType.contentSuggestion));
    });

    test('Neural Memory Engine dynamically extracts decisions and preferences from turns', () {
      final initialCount = MemoryEngine.activeMemories.length;
      MemoryEngine.extractFromConversation('Mulai sekarang kita tetapkan diskon 15% untuk member baru', '');
      expect(MemoryEngine.activeMemories.length, greaterThan(initialCount));
      expect(MemoryEngine.activeMemories.first.type, equals('decision'));
    });

    test('Supri AI responds naturally to human conversations like a real coworker', () {
      final items = <InventoryItem>[];
      final finance = FinancialSummary.demo();

      // 1. Natural appreciation / thanks ("ok makasi supro")
      final thanksAnswer = MemoryEngine.answerUserQuery(
        'ok makasi supro',
        items,
        finance,
      );
      expect(thanksAnswer.text.toLowerCase().contains('sama-sama') || thanksAnswer.text.toLowerCase().contains('santai') || thanksAnswer.text.toLowerCase().contains('seneng'), isTrue);
      // Must NEVER contain rigid bot menu
      expect(thanksAnswer.text.contains('Bos bisa tanya:'), isFalse);

      // 2. CSV report request ("pri bisa ga bikinin laporan dalam bentuk csv")
      final csvAnswer = MemoryEngine.answerUserQuery(
        'pri bisa ga bikinin laporan dalam bentuk csv',
        items,
        finance,
      );
      expect(csvAnswer.text.toLowerCase().contains('report') || csvAnswer.text.toLowerCase().contains('csv'), isTrue);
      expect(csvAnswer.text.contains('Bos bisa tanya:'), isFalse);

      // 3. Casual human small talk ("lagi ngapain pri")
      final smallTalkAnswer = MemoryEngine.answerUserQuery(
        'lagi ngapain pri',
        items,
        finance,
      );
      expect(smallTalkAnswer.text.toLowerCase().contains('standby') || smallTalkAnswer.text.toLowerCase().contains('ngopi'), isTrue);
      expect(smallTalkAnswer.text.contains('Bos bisa tanya:'), isFalse);
    });

    test('AI executes user instruction to clear dashboard data and restore demo data', () async {
      final store = InventoryStore();
      expect(store.allItems.isNotEmpty, isTrue);

      // Execute wipe command (exact user prompt: "kosongin dlu dasboard nya")
      await store.sendMessageToSupri('kosongin dlu dasboard nya');

      // Verify items are cleared!
      expect(store.allItems.isEmpty, isTrue);
      expect(store.chatMessages.last.text.contains('berhasil dikosongkan total'), isTrue);

      // Restore demo data
      await store.sendMessageToSupri('reset data');
      expect(store.allItems.isNotEmpty, isTrue);
      expect(store.chatMessages.last.text.contains('berhasil dipulihkan'), isTrue);
    });

    test('AI chat message supports image and file attachments', () async {
      final store = InventoryStore();
      await store.sendMessageToSupri(
        'Tolong cek foto produk ini',
        imageUrl: 'https://example.com/backpack.jpg',
        fileName: 'backpack.jpg',
      );

      final lastUserMsg = store.chatMessages[store.chatMessages.length - 2];
      expect(lastUserMsg.attachedImageUrl, equals('https://example.com/backpack.jpg'));
      expect(lastUserMsg.attachedFileName, equals('backpack.jpg'));
    });
  });
}
