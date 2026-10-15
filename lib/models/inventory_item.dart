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
  });

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
    );
  }
}
