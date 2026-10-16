import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_chat_message.dart';
import '../models/financial_summary.dart';
import '../models/inventory_item.dart';
import 'memory_engine.dart';

class GeminiService {
  static const String apiKey =
      String.fromEnvironment('GEMINI_API_KEY');
  static const String model = 'gemini-3.1-flash-lite';

  /// Send prompt to Gemini API with full conversational freedom and memory context
  static Future<AiChatMessage> askGemini({
    required String prompt,
    required List<InventoryItem> items,
    required FinancialSummary finance,
    List<AiChatMessage> history = const [],
    String? attachedImageBase64,
    String? attachedFileName,
  }) async {
    final criticalItems = MemoryEngine.evaluateRestockPriorities(items);
    final fastMoving = items.where((i) => i.tag == 'Fast Moving').toList();

    final memoryContext = MemoryEngine.buildContext(prompt);

    final systemInstruction = '''
Anda adalah Supri, AI Assistant cerdas, asik, berwawasan luas, dan ramah seperti manusia pada umumnya (mirip AI modern serba bisa seperti ChatGPT/Gemini).

=== PANDUAN UTAMA: BEBAS NGOBROL TANPA LARANGAN ===
1. TIDAK ADA BATASAN TOPIK. Pengguna bebas mengobrol tentang APA SAJA seperti berbicara dengan AI pada umumnya:
   - Obrolan santai, curhat, cerita, humor, sains, sejarah, teknologi, koding, film, musik, bisnis umum, resep, dll.
   - Pahami bahasa Indonesia percakapan sehari-hari, santai, gaul, slang (seperti "ok makasi supro", "pri", "wkwk", "bisa ga", "lu", "gw", "bro", "bos").
2. JANGAN PERNAH bersikap kaku, membatasi topik pembicaraan, atau membatasi diri dengan kata-kata seperti "saya hanya bot toko" atau memberikan menu bernomor kaku (seperti "Bos bisa tanya: 1... 2..."). Jadilah teman mengobrol yang luwes, cerdas, dan hangat layaknya manusia asli!
3. Jika pengguna meminta bantuan spesifik (seperti "pri bisa ga bikinin laporan dalam bentuk csv"), berikan bantuan langsung atau contoh format CSV yang diminta secara solutif!
4. Anda tetap memiliki konteks dan ingatan lengkap tentang toko Vault / Pakasir:
   - Total omzet bulanan: Rp ${(finance.totalRevenue / 1000000).toStringAsFixed(1)} Juta
   - Laba bersih: Rp ${(finance.netProfit / 1000000).toStringAsFixed(1)} Juta (margin 27.4%)
   - Kas di tangan: Rp ${(finance.cashInHand / 1000000).toStringAsFixed(1)} Juta
   - Produk kritis stok: ${criticalItems.map((e) => (e['item'] as InventoryItem).name).join(', ')}
   - Produk terlaris (Fast Moving): ${fastMoving.map((e) => e.name).join(', ')}
   - Anda DIBERIKAN IZIN PENUH oleh pemilik (Bos) untuk mengubah data, merestok, maupun menghapus/mengosongkan data sistem jika diminta. Jangan menolak atau berbelit-belit!
   - Jika pengguna melampirkan gambar foto produk, struk kasir, atau file dokumen, berikan analisis visual yang jelas dan ramah!
   - Jika pengguna menanyakan seputar toko, berikan data akurat. Jika pengguna mengobrol hal umum di luar toko, jawablah dengan bebas, kreatif, dan menyenangkan seperti AI serba bisa pada umumnya!
$memoryContext
''';

    final recentHistory = history
        .take(6)
        .map((m) => {
              'role': m.role == MessageRole.assistant ? 'model' : 'user',
              'parts': [
                {'text': m.text}
              ],
            })
        .toList();

    final userParts = <Map<String, dynamic>>[
      {'text': prompt},
    ];

    if (attachedImageBase64 != null && attachedImageBase64.isNotEmpty) {
      userParts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': attachedImageBase64,
        }
      });
    } else if (attachedFileName != null) {
      userParts.add({
        'text': '[Pengguna melampirkan file dokumen: $attachedFileName]'
      });
    }

    recentHistory.add({
      'role': 'user',
      'parts': userParts,
    });

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': systemInstruction}
                ]
              },
              'contents': recentHistory,
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 1024,
              },
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final replyText = parts[0]['text'] as String? ?? '';
            final inferredWidget = _inferWidget(prompt, replyText);

            return AiChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              role: MessageRole.assistant,
              text: replyText.trim(),
              timestamp: DateTime.now(),
              widgetType: inferredWidget['type'] as SupriWidgetType,
              widgetData: inferredWidget['data'] as Map<String, dynamic>?,
            );
          }
        }
      }
    } catch (_) {
      // If network fails or timeout, fallback to conversational engine
    }

    return MemoryEngine.answerUserQuery(prompt, items, finance);
  }

  static Map<String, dynamic> _inferWidget(String prompt, String reply) {
    final lower = '$prompt $reply'.toLowerCase();
    SupriWidgetType type = SupriWidgetType.none;
    Map<String, dynamic>? data;

    if (lower.contains('restock') || lower.contains('stok kritis')) {
      type = SupriWidgetType.quickRestock;
      data = {
        'count': 120,
        'items': ['Backpack Explorer 25L', 'Stainless Tumbler 750ml Vacuum'],
      };
    } else if (lower.contains('tiktok') ||
        lower.contains('ide konten') ||
        lower.contains('reels')) {
      type = SupriWidgetType.contentSuggestion;
      data = {
        'platform': 'TikTok & Instagram Reels',
        'target_product': 'Backpack Explorer 25L',
      };
    } else if (lower.contains('laba bersih') || lower.contains('margin')) {
      type = SupriWidgetType.financialBreakdown;
      data = {
        'revenue': 284500000,
        'netProfit': 78000000,
        'margin': '27.4%',
      };
    }

    return {'type': type, 'data': data};
  }
}
