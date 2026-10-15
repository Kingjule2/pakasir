import 'package:flutter/material.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';

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
    final criticalCount = store.allItems
        .where((item) => item.stockIn < item.totalQty * 0.3 || item.isOutOfStock)
        .length;
    final totalDailyOutletSales = store.outlets
        .fold<double>(0, (sum, o) => sum + (o.isOpen ? o.dailySales : 0));
    final openOutletsCount = store.outlets.where((o) => o.isOpen).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome & Quick Action Hero Bar
          _buildHeroWelcome(context, openOutletsCount, criticalCount),

          const SizedBox(height: 18),

          // 2. 4 Executive KPI Cards
          _buildExecutiveKpiCards(context, totalDailyOutletSales, criticalCount),

          const SizedBox(height: 18),

          // 3. Middle Section: Revenue Trend & Store Outlets Leaderboard
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 950) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 13,
                      child: _buildSalesVelocityChartCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 11,
                      child: _buildOutletsLeaderboardCard(context),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSalesVelocityChartCard(),
                    const SizedBox(height: 16),
                    _buildOutletsLeaderboardCard(context),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 18),

          // 4. Bottom Section: Top Products & Realtime Activity Stream
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 950) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 14,
                      child: _buildTopSellingProductsCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 10,
                      child: _buildLiveActivityCard(),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTopSellingProductsCard(),
                    const SizedBox(height: 16),
                    _buildLiveActivityCard(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroWelcome(
    BuildContext context,
    int openOutlets,
    int criticalCount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Selamat Datang kembali, Evano!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandLime.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.brandLime.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'LIVE SYSTEM',
                                style: TextStyle(
                                  color: AppColors.brandLime,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Semua data terhubung secara realtime: $openOutlets cabang beroperasi aktif, ${criticalCount > 0 ? '$criticalCount stok butuh restock' : 'semua stok aman'}.',
                          style: const TextStyle(
                            color: AppColors.textMutedOnDark,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: onNavigateToInventory,
                    icon: const Icon(Icons.inventory_2_outlined, size: 15),
                    label: const Text('Kelola Stok Inventaris'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandLime,
                      foregroundColor: AppColors.cardDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenSupri,
                    icon: const Icon(
                      Icons.smart_toy_rounded,
                      size: 15,
                      color: AppColors.brandLime,
                    ),
                    label: const Text(
                      'Tanya Supri AI',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onNavigateToCustomers,
                    icon: const Icon(
                      Icons.people_alt_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'CRM Pelanggan',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onNavigateToReports,
                    icon: const Icon(
                      Icons.insights_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Laporan Keuangan',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExecutiveKpiCards(
    BuildContext context,
    double totalDailySales,
    int criticalCount,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = constraints.maxWidth > 860
            ? (constraints.maxWidth - 3 * 14) / 4
            : (constraints.maxWidth - 14) / 2;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildMetricItem(
                title: 'Penjualan Hari Ini',
                value: 'Rp ${_formatRupiah(totalDailySales)}',
                badgeText: '+18.4% vs kemarin',
                isPositive: true,
                icon: Icons.payments_outlined,
                iconColor: AppColors.statusSuccess,
                bgColor: Colors.white,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricItem(
                title: 'Omset Bulan Ini',
                value: 'Rp ${_formatRupiah(store.finance.totalRevenue)}',
                badgeText: '+12.6% vs target',
                isPositive: true,
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.brandLime,
                bgColor: Colors.white,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricItem(
                title: 'Pelanggan Terdaftar',
                value: '${store.customers.length * 180} User',
                badgeText: '${store.customers.where((c) => c.tier == 'VIP').length * 24} VIP',
                isPositive: true,
                icon: Icons.people_outline_rounded,
                iconColor: AppColors.statusInfo,
                bgColor: Colors.white,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricItem(
                title: 'Alert Stok Rendah',
                value: '$criticalCount Produk',
                badgeText: criticalCount > 0 ? 'Perlu Restock' : 'Aman Terkendali',
                isPositive: criticalCount == 0,
                icon: Icons.warning_amber_rounded,
                iconColor: criticalCount > 0 ? AppColors.statusDanger : AppColors.statusSuccess,
                bgColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required String badgeText,
    required bool isPositive,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPositive
                  ? AppColors.statusSuccessBg
                  : AppColors.statusDangerBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 11,
                  color: isPositive
                      ? AppColors.statusSuccess
                      : AppColors.statusDanger,
                ),
                const SizedBox(width: 4),
                Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? AppColors.statusSuccess
                        : AppColors.statusDanger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesVelocityChartCard() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final heights = [35.0, 48.0, 42.0, 58.0, 68.0, 80.0, 62.0];
    final values = ['32Jt', '41Jt', '38Jt', '52Jt', '68Jt', '82Jt', '61Jt'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Puncak penjualan terjadi pada Jumat & Sabtu malam',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandLimeSoftBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.brandLime.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'Target 88% Tercapai',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cardDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(days.length, (index) {
                final isToday = index == 5; // Sabtu peak
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      values[index],
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isToday ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.brandLime : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isToday ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutletsLeaderboardCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performa Cabang Toko',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: onNavigateToStore,
                child: const Text(
                  'Lihat Semua >',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cardDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: store.outlets.length,
            separatorBuilder: (context, index) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final outlet = store.outlets[index];
              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: outlet.isOpen
                          ? AppColors.statusSuccessBg
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: outlet.isOpen
                              ? AppColors.statusSuccess
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outlet.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${outlet.city} • ${outlet.terminalsCount} Terminal POS',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp ${_formatRupiah(outlet.dailySales)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: outlet.isOpen
                              ? AppColors.statusSuccessBg
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          outlet.isOpen ? 'Buka' : 'Tutup',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: outlet.isOpen
                                ? AppColors.statusSuccess
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingProductsCard() {
    final topItems = store.allItems.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Produk Paling Laris',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: onNavigateToInventory,
                child: const Text(
                  'Lihat Inventaris >',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cardDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topItems.length,
            separatorBuilder: (context, index) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final item = topItems[index];
              return Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'SKU: ${item.sku} • ${item.category}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp ${_formatRupiah(item.price)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Sisa ${item.stockIn} unit',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.stockIn < 30
                              ? AppColors.statusDanger
                              : AppColors.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveActivityCard() {
    final activities = [
      {
        'title': 'Pesanan Kasir #ORD-9912 Selesai',
        'sub': 'Cabang SCBD • Pembayaran QRIS Rp 450.000',
        'time': '3 mnt lalu',
        'icon': Icons.receipt_long_rounded,
        'color': AppColors.statusSuccess,
      },
      {
        'title': 'Restock Otomatis Direspon Supplier',
        'sub': '120 Unit Backpack & Watch X dalam perjalanan',
        'time': '25 mnt lalu',
        'icon': Icons.local_shipping_outlined,
        'color': AppColors.supriOrange,
      },
      {
        'title': 'Pelanggan VIP Baru Ditambahkan',
        'sub': 'Budi Santoso bergabung program loyalty',
        'time': '1 jam lalu',
        'icon': Icons.person_add_alt_1_rounded,
        'color': AppColors.statusInfo,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktivitas Sistem Terkini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.statusSuccess,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final act = activities[index];
              final color = act['color'] as Color;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(act['icon'] as IconData, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act['title'] as String,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          act['sub'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    act['time'] as String,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _formatRupiah(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} M';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} Jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} Rb';
    }
    return amount.toStringAsFixed(0);
  }
}
