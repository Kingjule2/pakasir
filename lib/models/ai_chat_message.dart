enum MessageRole { user, assistant }

enum SupriWidgetType {
  none,
  quickRestock,
  contentSuggestion,
  financialBreakdown,
  lowStockAlert,
}

class AiChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final SupriWidgetType widgetType;
  final Map<String, dynamic>? widgetData;
  final String? attachedImageUrl;
  final String? attachedFileName;
  final String? attachedImageBase64;

  AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.widgetType = SupriWidgetType.none,
    this.widgetData,
    this.attachedImageUrl,
    this.attachedFileName,
    this.attachedImageBase64,
  });
}
