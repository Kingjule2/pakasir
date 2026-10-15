class ShipmentItem {
  final String id;
  final String productName;
  final String sku;
  final int delayedDays;
  final String supplier;
  final String imageAsset;

  ShipmentItem({
    required this.id,
    required this.productName,
    required this.sku,
    required this.delayedDays,
    required this.supplier,
    this.imageAsset = 'default',
  });
}
