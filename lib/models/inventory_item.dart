enum PriorityLevel { high, medium, low }

class InventoryItem {
  final String id;
  final String name;
  final String sku;
  final String category;
  final int totalQty;
  int stockIn;
  final double price;
  final double costPrice;
  final PriorityLevel priority;
  final String tag;
  final String imageAsset;
  final bool isOutOfStock;
  final DateTime? deletedAt;
  final DateTime? deleteAfter;
  final String? deletedReason;
  final DateTime? expiryDate;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.totalQty,
    required this.stockIn,
    required this.price,
    required this.costPrice,
    required this.priority,
    required this.tag,
    this.imageAsset = 'default',
    this.isOutOfStock = false,
    this.deletedAt,
    this.deleteAfter,
    this.deletedReason,
    this.expiryDate,
  });

  int get daysRemaining {
    if (deleteAfter == null) return 30;
    final diff = deleteAfter!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isNearExpiry {
    if (expiryDate == null) return false;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 14;
  }

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  bool get isLowStock => totalQty <= 20 || stockIn <= 15;
  InventoryItem copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    int? totalQty,
    int? stockIn,
    double? price,
    double? costPrice,
    PriorityLevel? priority,
    String? tag,
    String? imageAsset,
    bool? isOutOfStock,
    DateTime? deletedAt,
    DateTime? deleteAfter,
    String? deletedReason,
    DateTime? expiryDate,
    bool clearDeleted = false,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      totalQty: totalQty ?? this.totalQty,
      stockIn: stockIn ?? this.stockIn,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      priority: priority ?? this.priority,
      tag: tag ?? this.tag,
      imageAsset: imageAsset ?? this.imageAsset,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      deletedAt: clearDeleted ? null : (deletedAt ?? this.deletedAt),
      deleteAfter: clearDeleted ? null : (deleteAfter ?? this.deleteAfter),
      deletedReason: clearDeleted ? null : (deletedReason ?? this.deletedReason),
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
