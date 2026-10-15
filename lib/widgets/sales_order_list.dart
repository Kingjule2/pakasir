import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../theme/app_colors.dart';

class SalesOrderListCard extends StatelessWidget {
  final List<InventoryItem> items;
  final ValueChanged<String> onDeleteItem;

  const SalesOrderListCard({
    super.key,
    required this.items,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sales & Order',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded, size: 16),
                color: AppColors.textMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 16),
                color: AppColors.textMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Monthly',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Header line
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Product Name',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Price',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Priority',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Action',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF5F6F8)),

          // Product List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.take(4).length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.8,
              color: Color(0xFFF5F6F8),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    // Product Name & Stock status
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          _buildThumb(item),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.isOutOfStock
                                      ? 'Out of stock'
                                      : '${item.stockIn} In Stock',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                    color: item.isOutOfStock
                                        ? AppColors.statusDanger
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Expanded(
                      flex: 3,
                      child: Text(
                        '\$${item.price.toInt()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Priority Pill
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: _buildPriorityPill(item.priority),
                      ),
                    ),
                    // Action Icons
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => onDeleteItem(item.id),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 15,
                              color: Color(0xFFB0B7C3),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(InventoryItem item) {
    Color bg = const Color(0xFFF1F5F9);
    IconData icon = Icons.shopping_bag_outlined;

    if (item.name.toLowerCase().contains('backpack')) {
      bg = const Color(0xFFE2E8F0);
      icon = Icons.backpack_outlined;
    } else if (item.name.toLowerCase().contains('bag')) {
      bg = const Color(0xFFFEF3C7);
      icon = Icons.luggage_outlined;
    } else if (item.name.toLowerCase().contains('headphone')) {
      bg = const Color(0xFFEDE9FE);
      icon = Icons.headphones_outlined;
    } else if (item.name.toLowerCase().contains('bottle')) {
      bg = const Color(0xFFE0F2FE);
      icon = Icons.local_drink_outlined;
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: AppColors.textSecondary),
    );
  }

  Widget _buildPriorityPill(PriorityLevel priority) {
    Color bg;
    Color text;
    String label;

    switch (priority) {
      case PriorityLevel.high:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF16A34A);
        label = 'High';
        break;
      case PriorityLevel.medium:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        label = 'Medium';
        break;
      case PriorityLevel.low:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
