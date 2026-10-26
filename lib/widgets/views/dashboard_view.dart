import 'package:flutter/material.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';
import '../charts/stock_level_donut_chart.dart';

class DashboardView extends StatelessWidget {
  final InventoryStore store;
  final VoidCallback onNavigateToInventory;
  final VoidCallback onNavigateToCustomers;
  final VoidCallback onNavigateToStore;
  final VoidCallback onNavigateToReports;
  final VoidCallback onOpenSupri;
  final VoidCallback onAddProduct;

  const DashboardView({
    super.key,
    required this.store,
    required this.onNavigateToInventory,
    required this.onNavigateToCustomers,
    required this.onNavigateToStore,
    required this.onNavigateToReports,
    required this.onOpenSupri,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final criticalItems = store.allItems
        .where((item) => item.stockIn < item.totalQty * 0.3 || item.isOutOfStock)
        .toList();
    final criticalCount = criticalItems.length;
    final totalDailyOutletSales = store.outlets
        .fold<double>(0, (sum, o) => sum + (o.isOpen ? o.dailySales : 0));

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isCompact = outerConstraints.maxWidth < 360;
        final horizontalPad = isCompact ? 12.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Stitch Header Greeting & Date Badge
              _buildStitchGreetingRow(context),

              const SizedBox(height: 12),

              // 2. Stitch Quick Action Pills (Horizontal Scroll)
              _buildQuickActionPills(),

              const SizedBox(height: 14),

              // 3. Stitch 2x2 Grid KPI Summary Cards
              _buildStitchKpiGrid(totalDailyOutletSales, criticalCount),

              const SizedBox(height: 14),

              // 4. Stitch Stock Level Donut Card
              StockLevelDonutChartCard(
                inStock: store.allItems.where((i) => i.stockIn >= 30 && !i.isOutOfStock).length,
                lowStock: store.allItems.where((i) => i.stockIn > 0 && i.stockIn < 30).length,
                outOfStock: store.allItems.where((i) => i.stockIn <= 0 || i.isOutOfStock).length,
              ),

              const SizedBox(height: 14),

              // 5. Stitch Sales Overview Smooth Area Chart Card
              _buildStitchSalesOverviewCard(),

              const SizedBox(height: 14),

              // 6. Stitch Stock Alerts Compact List
              _buildStitchStockAlertsCard(context, criticalItems),

              const SizedBox(height: 14),

              // 7. Fast Selling Products List (Top Produk Paling Laris)
              _buildTopSellingProductsCard(),

              const SizedBox(height: 14),

              // 8. Performa Cabang Toko (Outlets Leaderboard)
              _buildOutletsLeaderboardCard(),

              const SizedBox(height: 14),

              // 9. Aktivitas Sistem Terkini
              _buildLiveActivityCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStitchGreetingRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'Selamat Datang kembali, Evano!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141B2B),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E9E4F),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 5,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Evano (Owner)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Text('•', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1E8FD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF46464F),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 5),
              Text(
                'Sel, 26 Okt',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF141B2B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          InkWell(
            onTap: onAddProduct,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF12134D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Add product',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => store.setActiveNav('POS'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.point_of_sale_rounded, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    'New sale',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF141B2B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onNavigateToInventory,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    'Scan SKU',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF141B2B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onOpenSupri,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFE1E8FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_toy_outlined, size: 16, color: Color(0xFF12134D)),
                  SizedBox(width: 6),
                  Text(
                    'Tanya Supri AI',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF12134D)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchKpiGrid(double totalDailySales, int criticalCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 10.0;
        final cardWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildStitchKpiCard(
                title: 'Penjualan Hari Ini',
                value: 'Rp ${_formatShortRupiah(totalDailySales)}',
                badgeText: '20%',
                isPositive: true,
                icon: Icons.trending_up_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStitchKpiCard(
                title: 'Omset Bulan Ini',
                value: 'Rp 284,5 Jt',
                badgeText: '15%',
                isPositive: true,
                icon: Icons.shopping_bag_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStitchKpiCard(
                title: 'Pelanggan Terdaftar',
                value: '${store.customers.length * 180} User',
                badgeText: '${store.customers.where((c) => c.tier == 'VIP').length * 24} VIP',
                isPositive: true,
                icon: Icons.people_outline_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStitchKpiCard(
                title: 'Alert Stok Rendah',
                value: '$criticalCount Produk',
                badgeText: criticalCount > 0 ? 'Restock' : 'Aman',
                isPositive: criticalCount == 0,
                icon: Icons.assignment_return_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStitchKpiCard({
    required String title,
    required String value,
    required String badgeText,
    required bool isPositive,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 15, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF141B2B),
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFFDDF5E5) : const Color(0xFFFDE3E3),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 11,
                  color: isPositive ? const Color(0xFF1E9E4F) : const Color(0xFFD83A3A),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? const Color(0xFF1E9E4F) : const Color(0xFFD83A3A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchSalesOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Penjualan 7 Hari Terakhir',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141B2B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Monthly trajectory • Peak Jumat & Sabtu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '6M',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF141B2B)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '1Y',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _StitchAreaChartPainter(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('May', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('Jun', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('Jul', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('Aug', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('Sep', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('Oct', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF12134D))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStitchStockAlertsCard(BuildContext context, List<dynamic> criticalItems) {
    final displayItems = criticalItems.isNotEmpty
        ? criticalItems.take(3).toList()
        : store.allItems.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Stock Alerts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF141B2B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${displayItems.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF93000A),
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  store.executeAllRecommendedRestock();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restock otomatis barang kritis berhasil dijalankan!')),
                  );
                },
                child: const Text(
                  'Restock Now',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D6FB5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...displayItems.map((item) {
            final isOut = item.stockIn <= 0 || item.isOutOfStock;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF12134D)),
                  ),
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF141B2B),
                          ),
                        ),
                        Text(
                          '${item.category} • ${item.stockIn} unit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOut ? const Color(0xFFFDE3E3) : const Color(0xFFD6E8FB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isOut ? const Color(0xFFD83A3A) : const Color(0xFF2D6FB5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOut ? 'Out of stock' : 'Low stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isOut ? const Color(0xFFD83A3A) : const Color(0xFF2D6FB5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopSellingProductsCard() {
    final topItems = store.allItems.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Top Produk Paling Laris',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141B2B),
                  ),
                ),
              ),
              InkWell(
                onTap: onNavigateToInventory,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D6FB5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...topItems.map((item) {
            final isLow = item.stockIn < 30;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF12134D)),
                  ),
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF141B2B),
                          ),
                        ),
                        Text(
                          '${item.sku} • ${item.stockIn} unit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLow ? const Color(0xFFD6E8FB) : const Color(0xFFDDF5E5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isLow ? 'Low Stock' : 'In Stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isLow ? const Color(0xFF2D6FB5) : const Color(0xFF1E9E4F),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOutletsLeaderboardCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Performa Cabang Toko',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141B2B),
                  ),
                ),
              ),
              InkWell(
                onTap: onNavigateToStore,
                child: const Text(
                  'Lihat Semua >',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF12134D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...store.outlets.asMap().entries.map((entry) {
            final index = entry.key;
            final outlet = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: outlet.isOpen ? const Color(0xFFDDF5E5) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: outlet.isOpen ? const Color(0xFF1E9E4F) : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outlet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF141B2B)),
                        ),
                        Text(
                          '${outlet.city} • ${outlet.terminalsCount} POS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp ${_formatShortRupiah(outlet.dailySales)}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF141B2B)),
                      ),
                      Text(
                        outlet.isOpen ? 'Buka' : 'Tutup',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: outlet.isOpen ? const Color(0xFF1E9E4F) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLiveActivityCard() {
    final activities = [
      {
        'title': 'Pesanan Baru #ORD-8829 Selesai',
        'sub': 'Vault Central SCBD • Pembayaran QRIS Rp 450.000',
        'time': '2 menit lalu',
        'color': const Color(0xFF1E9E4F),
      },
      {
        'title': 'Memory Engine Mendeteksi Stok Rendah',
        'sub': 'Backpack Explorer (SKU-770) tersisa 25 unit',
        'time': '14 menit lalu',
        'color': const Color(0xFF2D6FB5),
      },
      {
        'title': 'Sinkronisasi Cloud Multi-Outlet',
        'sub': 'Data penjualan 3 cabang aktif berhasil diperbarui',
        'time': '1 jam lalu',
        'color': const Color(0xFF12134D),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Aktivitas Sistem Terkini',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141B2B),
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E9E4F),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...activities.map((act) {
            final color = act['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act['title'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF141B2B)),
                        ),
                        Text(
                          act['sub'] as String,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                        Text(
                          act['time'] as String,
                          style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatShortRupiah(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} Jt';
    }
    return value.toStringAsFixed(0);
  }
}

class _StitchAreaChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F3FF)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h * 0.2), Offset(w, h * 0.2), gridPaint);
    canvas.drawLine(Offset(0, h * 0.6), Offset(w, h * 0.6), gridPaint);

    final linePath = Path()
      ..moveTo(0, h * 0.85)
      ..cubicTo(w * 0.13, h * 0.78, w * 0.20, h * 0.60, w * 0.32, h * 0.65)
      ..cubicTo(w * 0.44, h * 0.70, w * 0.53, h * 0.35, w * 0.65, h * 0.40)
      ..cubicTo(w * 0.76, h * 0.45, w * 0.85, h * 0.15, w, h * 0.10);

    final areaPath = Path.from(linePath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xB3BDDDFF), Color(0x00BDDDFF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(areaPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF12134D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, strokePaint);

    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = const Color(0xFF12134D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(w, h * 0.10), 4, dotFill);
    canvas.drawCircle(Offset(w, h * 0.10), 4, dotStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
