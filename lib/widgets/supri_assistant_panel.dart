import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_chat_message.dart';
import '../models/inventory_item.dart';
import '../theme/app_colors.dart';
import 'neural_memory_dialog.dart';
import '../services/tts/tts_service.dart';
class SupriAssistantPanel extends StatefulWidget {
  final List<AiChatMessage> messages;
  final ValueChanged<String> onSendMessage;
  final void Function(String text, {String? imageUrl, String? fileName, String? base64})? onSendAttachmentMessage;
  final VoidCallback onClose;
  final VoidCallback onExecuteRestock;
  final List<InventoryItem> items;

  const SupriAssistantPanel({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.onSendAttachmentMessage,
    required this.onClose,
    required this.onExecuteRestock,
    required this.items,
  });

  @override
  State<SupriAssistantPanel> createState() => _SupriAssistantPanelState();
}

class _SupriAssistantPanelState extends State<SupriAssistantPanel>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _attachedImageUrl;
  String? _attachedFileName;
  String? _attachedImageBase64;
  bool _isThinking = false;
  bool _isMicActive = false;
  late AnimationController _gearController;
  late Animation<double> _gearAnimation;

  void _handleMicPressed() {
    setState(() {
      _isMicActive = !_isMicActive;
    });

    if (!_isMicActive) {
      TtsService.stop();
      return;
    }

    const greeting =
        'Halo Bos! Supri di sini, siap bantu kelola inventaris, cek stok, atau analisa omzet toko hari ini. Mau cek apa nih Bos?';

    widget.onSendMessage('Halo Supri!');

    TtsService.speakNaturalMaleIndonesian(greeting, onComplete: () {
      if (mounted) {
        setState(() {
          _isMicActive = false;
        });
      }
    });
  }
  @override
  void initState() {
    super.initState();
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _gearAnimation = Tween<double>(begin: 0, end: 1).animate(_gearController);
  }

  @override
  void dispose() {
    _gearController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  final List<String> _quickPrompts = [
    'Berapa laba bersih minggu ini?',
    'Bagaimana analisis tren penjualan?',
    'Kasih saran pemasaran & ide konten!',
    'Barang apa yang mau habis?',
    'Apa saja memori yang kamu ingat?',
  ];

  @override
  void didUpdateWidget(covariant SupriAssistantPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Supri Mascot Header
          _buildPanelHeader(),

          // Memory Engine Status Strip
          _buildMemoryEngineStatus(),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: widget.messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == widget.messages.length) {
                  return _buildThinkingIndicator();
                }
                final msg = widget.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Quick Prompt Pills
          _buildQuickPrompts(),

          // Message Composer
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 14),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
      ),
      child: Row(
        children: [
          // Supri Avatar Mascot
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.supriOrange, AppColors.brandLime],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppColors.cardDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Supri',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Super Intelligent',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandLime,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Mitra Bisnis & Asisten UMKM',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMutedOnDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textMutedOnDark,
              size: 18,
            ),
            tooltip: 'Tutup panel Supri',
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryEngineStatus() {
    return InkWell(
      onTap: () => NeuralMemoryDialog.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFFF9FAFB),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.statusSuccess,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Memory Engine 6-Bulan Aktif • Pola Tren Gudang Terhubung',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandLime.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cardDark,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 12, color: AppColors.cardDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage msg) {
    final isAssistant = msg.role == MessageRole.assistant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment:
            isAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment:
                isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAssistant) ...[
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.supriOrange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 15,
                    color: AppColors.supriOrange,
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isAssistant
                        ? const Color(0xFFF4F6F8)
                        : AppColors.cardDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isAssistant ? 2 : 14),
                      bottomRight: Radius.circular(isAssistant ? 14 : 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.attachedImageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 140, maxWidth: 220),
                            color: Colors.black12,
                            child: Image.network(
                              msg.attachedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                padding: const EdgeInsets.all(10),
                                color: Colors.black26,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.image_rounded, size: 18, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        msg.attachedFileName ?? 'Foto Terlampir',
                                        style: const TextStyle(fontSize: 10.5, color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ] else if (msg.attachedFileName != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAssistant ? Colors.black.withValues(alpha: 0.06) : Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insert_drive_file_rounded,
                                size: 14,
                                color: isAssistant ? AppColors.supriOrange : AppColors.brandLime,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  msg.attachedFileName!,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isAssistant ? AppColors.textPrimary : Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (msg.text.isNotEmpty)
                        Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: isAssistant
                                ? AppColors.textPrimary
                                : Colors.white,
                            height: 1.4,
                          ),
                        ),
                      if (isAssistant && msg.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: InkWell(
                            onTap: () => TtsService.speakNaturalMaleIndonesian(msg.text),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.volume_up_rounded, size: 13, color: AppColors.supriOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dengarkan Suara Supri',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.supriOrange.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Mini-Widgets embedded in chat bubble
          if (msg.widgetType == SupriWidgetType.quickRestock)
            _buildRestockMiniWidget(msg.widgetData),
          if (msg.widgetType == SupriWidgetType.contentSuggestion)
            _buildContentSuggestionWidget(msg.widgetData),
          if (msg.widgetType == SupriWidgetType.financialBreakdown)
            _buildFinancialMiniWidget(msg.widgetData),
        ],
      ),
    );
  }

  Widget _buildRestockMiniWidget(Map<String, dynamic>? data) {
    return Container(
      margin: const EdgeInsets.only(left: 34, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Rekomendasi Restock Cepat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Produk darurat: Backpack Explorer (sisa 25 unit), T-Shirts SKU-300.',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onExecuteRestock,
              icon: const Icon(Icons.flash_on_rounded, size: 14),
              label: const Text('Eksekusi Restock Sekarang (120 Unit)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardDark,
                foregroundColor: AppColors.brandLime,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSuggestionWidget(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();

    final hook = data['hook'] ?? '';
    final caption = data['caption'] ?? '';
    final platform = data['platform'] ?? 'TikTok';

    return Container(
      margin: const EdgeInsets.only(left: 34, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.video_library_rounded,
                        size: 15, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Draft Konten $platform',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14532D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '$hook\n\n$caption'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Draft konten disalin ke clipboard!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                color: const Color(0xFF16A34A),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Salin script',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '🎯 Hook: "$hook"',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📝 Caption:\n$caption',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMiniWidget(Map<String, dynamic>? data) {
    return Container(
      margin: const EdgeInsets.only(left: 34, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rangkuman Margin Bisnis Bulan Ini',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Margin Laba Kotor',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('41.0%',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.statusSuccess)),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Margin Laba Bersih',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('27.4%',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandLime)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickPrompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(
                  prompt,
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: const Color(0xFFF4F5F7),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onPressed: () async {
                  setState(() {
                    _isThinking = true;
                  });
                  _gearController.repeat();
                  _scrollToBottom();
                  try {
                    if (widget.onSendAttachmentMessage != null) {
                      widget.onSendAttachmentMessage!(prompt);
                    } else {
                      widget.onSendMessage(prompt);
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isThinking = false;
                      });
                      _gearController.stop();
                      _scrollToBottom();
                    }
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attachment Preview Chip if active
          if (_attachedFileName != null || _attachedImageUrl != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandLime),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _attachedImageUrl != null
                        ? Icons.image_rounded
                        : Icons.insert_drive_file_rounded,
                    size: 15,
                    color: AppColors.supriOrange,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      _attachedFileName ?? 'File Terlampir',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _attachedImageUrl = null;
                        _attachedFileName = null;
                        _attachedImageBase64 = null;
                      });
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: _showAttachmentPickerModal,
                icon: const Icon(Icons.attach_file_rounded, size: 20),
                color: AppColors.textSecondary,
                tooltip: 'Lampirkan file atau foto produk',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              // Mic Logo Button with immediate spoken greeting
              IconButton(
                onPressed: _handleMicPressed,
                icon: Icon(
                  _isMicActive ? Icons.mic_rounded : Icons.mic_none_rounded,
                  size: 20,
                  color: _isMicActive ? AppColors.brandLime : AppColors.supriOrange,
                ),
                tooltip: 'Sapa Supri lewat Suara (TTS Cowo Greeting)',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  backgroundColor:
                      _isMicActive ? AppColors.cardDark : Colors.transparent,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Tanya Supri apa saja (ketik bebas)...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (val) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _handleSend,
                icon: const Icon(Icons.send_rounded, size: 18),
                color: AppColors.cardDark,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandLime,
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isNotEmpty || _attachedFileName != null || _attachedImageUrl != null) {
      final imgUrl = _attachedImageUrl;
      final fName = _attachedFileName;
      final b64 = _attachedImageBase64;

      _inputController.clear();
      setState(() {
        _attachedImageUrl = null;
        _attachedFileName = null;
        _attachedImageBase64 = null;
        _isThinking = true;
      });
      _gearController.repeat();
      _scrollToBottom();

      try {
        if (widget.onSendAttachmentMessage != null) {
          widget.onSendAttachmentMessage!(
            text,
            imageUrl: imgUrl,
            fileName: fName,
            base64: b64,
          );
        } else {
          widget.onSendMessage(text);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isThinking = false;
          });
          _gearController.stop();
          _scrollToBottom();
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: AppColors.supriOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 15,
              color: AppColors.supriOrange,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Supri sedang berfikir...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                RotationTransition(
                  turns: _gearAnimation,
                  child: const Icon(
                    Icons.settings_rounded,
                    size: 16,
                    color: AppColors.supriOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lampirkan File atau Foto',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Supri dapat menganalisis foto produk, nota kasir, atau dokumen laporan',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.brandLime.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.cardDark, size: 20),
                ),
                title: const Text('Foto Produk (Backpack Explorer)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                subtitle: const Text('Kirim foto produk untuk dibuatkan ide konten viral', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _attachedFileName = 'Foto_Backpack_Explorer.jpg';
                    _attachedImageUrl = 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=400&q=80';
                  });
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.supriOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.supriOrange, size: 20),
                ),
                title: const Text('Struk Pembelian Kasir (Faktur POS)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                subtitle: const Text('Analisis nominal transaksi dan barang dari nota kasir', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _attachedFileName = 'Struk_Faktur_INV-20261013.jpg';
                    _attachedImageUrl = 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=400&q=80';
                  });
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.statusInfo.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.table_chart_rounded, color: AppColors.statusInfo, size: 20),
                ),
                title: const Text('File Laporan Penjualan (CSV / Excel)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                subtitle: const Text('Laporan_Penjualan_Toko_Oktober.csv', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _attachedFileName = 'Laporan_Penjualan_Toko_Oktober.csv';
                    _attachedImageUrl = null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
