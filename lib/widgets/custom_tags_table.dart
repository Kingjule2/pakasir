import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../theme/app_colors.dart';

class CustomTagsTableCard extends StatelessWidget {
  final List<String> tags;
  final String selectedTag;
  final ValueChanged<String> onTagSelected;
  final ValueChanged<String> onAddTag;
  final List<InventoryItem> items;
  final ValueChanged<String> onDeleteItem;

  const CustomTagsTableCard({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
    required this.onAddTag,
    required this.items,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Custom Tags & Labels',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Flexible(
                child: Text(
                  'Categories By AI Assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tag Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...tags.map((tag) {
                  final isSelected =
                      selectedTag.toLowerCase() == tag.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => onTagSelected(isSelected ? '' : tag),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cardDark
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cardDark
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Add Tag button
                InkWell(
                  onTap: () => _showAddTagDialog(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Add Tag',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F3F5), width: 1.2),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Products Details',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Total Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Stock In',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
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
                      fontSize: 11,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'No products found for this tag/search.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.take(5).length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF5F6F8),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Products Details
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            _buildProductAvatar(item.name, item.category),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.sku,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Total Qty
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatNumber(item.totalQty),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      // Stock In
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatNumber(item.stockIn),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      // Price
                      Expanded(
                        flex: 3,
                        child: Text(
                          '\$${(item.price >= 1000 ? '${(item.price / 1000).toStringAsFixed(0)}K' : item.price.toInt())}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      // Action
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => onDeleteItem(item.id),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Color(0xFFB0B7C3),
                              ),
                              tooltip: 'Delete item',
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

  Widget _buildProductAvatar(String name, String category) {
    Color bg = const Color(0xFFF1F5F9);
    IconData icon = Icons.inventory_2_rounded;

    if (category == 'Electronic' || name.toLowerCase().contains('headphone')) {
      bg = const Color(0xFFEDE9FE);
      icon = Icons.headphones_rounded;
    } else if (category == 'Fashion' || name.toLowerCase().contains('shirt')) {
      bg = const Color(0xFFE0F2FE);
      icon = Icons.checkroom_rounded;
    } else if (name.toLowerCase().contains('glass')) {
      bg = const Color(0xFFFEF3C7);
      icon = Icons.visibility_rounded;
    } else if (name.toLowerCase().contains('helmet')) {
      bg = const Color(0xFFDCFCE7);
      icon = Icons.sports_motorsports_rounded;
    } else if (name.toLowerCase().contains('pot') || category == 'Drinks') {
      bg = const Color(0xFFFEE2E2);
      icon = Icons.local_drink_rounded;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.textSecondary),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return number.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},',
          );
    }
    return number.toString();
  }

  void _showAddTagDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Tag', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Clearance, Best Seller',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAddTag(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cardDark),
            child: const Text('Add Tag', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
