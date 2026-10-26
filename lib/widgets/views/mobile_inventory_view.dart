import 'package:flutter/material.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';
import '../add_product_dialog.dart';

class MobileInventoryView extends StatefulWidget {
  final InventoryStore store;

  const MobileInventoryView({super.key, required this.store});

  @override
  State<MobileInventoryView> createState() => _MobileInventoryViewState();
}

class _MobileInventoryViewState extends State<MobileInventoryView> {
  String _selectedTab = 'active'; // 'active' or 'deleted'
  String _search = '';
  String _activeTag = 'Semua';

  InventoryStore get store => widget.store;

  @override
  Widget build(BuildContext context) {
    final activeItems = store.allItems.where((item) {
      final matchSearch = _search.isEmpty ||
          item.name.toLowerCase().contains(_search.toLowerCase()) ||
          item.sku.toLowerCase().contains(_search.toLowerCase()) ||
          item.category.toLowerCase().contains(_search.toLowerCase());
      final matchTag = _activeTag == 'Semua' ||
          item.tag.toLowerCase() == _activeTag.toLowerCase();
      return matchSearch && matchTag;
    }).toList();

    final recentlyDeleted = store.recentlyDeletedItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Mobile Header & Action
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Inventory & Stock',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tableHeaderBg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${store.allItems.length} Active SKUs across hubs',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AddProductDialog(
                      onAdd: (item) {
                        store.addProduct(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Produk "${item.name}" berhasil ditambahkan!')),
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Search Bar + Barcode Scanner Trigger
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      hintText: 'Search by name, SKU, or category...',
                      hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  store.setActiveNav('POS');
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primaryNavy),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Tab: Aktif vs Recently Deleted
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = 'active'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 'active' ? AppColors.primaryNavy : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Katalog Aktif (${store.allItems.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedTab == 'active' ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedTab == 'active' ? AppColors.primaryNavy : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = 'deleted'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == 'deleted' ? AppColors.primaryNavy : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Recently Deleted (${store.recentlyDeletedItems.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedTab == 'deleted' ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedTab == 'deleted' ? AppColors.primaryNavy : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (_selectedTab == 'active') ...[
            // Horizontal Tag Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'Semua',
                  'Fast Moving',
                  'Regular',
                  'Discounted',
                  'Low Demand',
                  'Dead Items',
                ].map((tag) {
                  final isSelected = _activeTag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(tag, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                      selectedColor: AppColors.primaryNavy,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                      backgroundColor: AppColors.surfaceAlt,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      side: BorderSide(color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle),
                      onSelected: (v) => setState(() => _activeTag = tag),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Product Cards List
            if (activeItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                child: const Text('Tidak ada produk yang cocok dengan pencarian.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeItems.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = activeItems[index];
                  final out = item.stockIn <= 0 || item.isOutOfStock;
                  final low = !out && item.stockIn < 30;
                  final marginPct = item.price > 0 ? (((item.price - item.costPrice) / item.price) * 100).round() : 0;
                  final progress = (item.stockIn / (item.totalQty > 0 ? item.totalQty : 1)).clamp(0.0, 1.0);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.tableHeaderBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _iconForCategory(item.category),
                                color: AppColors.primaryNavy,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text('${item.sku} • ${item.category}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: out
                                              ? const Color(0xFFFDE3E3)
                                              : low
                                                  ? const Color(0xFFD6E8FB)
                                                  : const Color(0xFFDDF5E5),
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        child: Text(
                                          out ? 'Out of Stock' : low ? 'Low Stock' : item.tag,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: out
                                                ? const Color(0xFFD83A3A)
                                                : low
                                                    ? const Color(0xFF2D6FB5)
                                                    : const Color(0xFF1E9E4F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 2,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text('Rp ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
                                      Text('HPP: Rp ${item.costPrice.toStringAsFixed(0)} • Margin $marginPct%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: AppColors.surfaceAlt,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              out ? AppColors.statusDanger : low ? AppColors.statusWarning : AppColors.primaryNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('${item.stockIn} / ${item.totalQty} unit tersedia', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    store.restockItem(item.id, 25);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('+25 unit ditambahkan ke ${item.name}!')),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text('+25 Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFD83A3A)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Soft Delete ke Recently Deleted',
                                  onPressed: () {
                                    store.softDeleteProduct(item.id, reason: 'Discontinued', holdDays: 30);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${item.name} dipindahkan ke Recently Deleted (retensi 30 hari).')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ] else ...[
            // Recently Deleted Screen
            if (recentlyDeleted.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 40, color: AppColors.textMuted),
                    SizedBox(height: 8),
                    Text('Tempat sampah bersih', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Tidak ada produk dalam masa retensi soft delete.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${recentlyDeleted.length} Produk dalam masa retensi', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    onPressed: () {
                      final count = store.purgeExpiredDeletedProducts(forceAll: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$count produk dihapus permanen!')),
                      );
                    },
                    icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Color(0xFFD83A3A)),
                    label: const Text('Bersihkan Semua', style: TextStyle(fontSize: 11, color: Color(0xFFD83A3A), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentlyDeleted.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = recentlyDeleted[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.name} (${item.sku})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('Alasan: ${item.deletedReason ?? "Discontinued"} • Sisa retensi: ${item.daysRemaining} hari', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            store.restoreProduct(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${item.name} dipulihkan ke katalog aktif!')),
                            );
                          },
                          icon: const Icon(Icons.restore_rounded, size: 14),
                          label: const Text('Restore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'electronic':
        return Icons.headphones_rounded;
      case 'watch':
        return Icons.watch_rounded;
      case 'fashion':
        return Icons.checkroom_rounded;
      case 'drinks':
        return Icons.local_drink_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }
}
