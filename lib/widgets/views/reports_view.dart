import 'package:flutter/material.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';

class ReportsView extends StatelessWidget {
  final InventoryStore store;
  final VoidCallback onBackToInventory;

  const ReportsView({
    super.key,
    required this.store,
    required this.onBackToInventory,
  });

  @override
  Widget build(BuildContext context) {
    final finance = store.finance;
    final periods = ['Hari Ini', '7 Hari Terakhir', 'Bulan Ini', 'Tahun Ini'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Toolbar: Period Selector & Export Actions
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan Keuangan & Analitik Penjualan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rekapitulasi laba rugi, perputaran kas, dan performa payment gateway',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Laporan ${store.reportPeriod} berhasil diekspor ke format Excel (CSV)!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.table_view_rounded, size: 14),
                        label: const Text('Export Excel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cardDark,
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Dokumen PDF Laporan Finansial ${store.reportPeriod} berhasil diunduh.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cardDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Period Pills
          Wrap(
            spacing: 8,
            children: periods.map((period) {
              final isSelected = store.reportPeriod == period;
              return InkWell(
                onTap: () => store.setReportPeriod(period),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.cardDark : AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // 2. 4 Core Financial KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth > 850
                  ? (constraints.maxWidth - 3 * 14) / 4
                  : (constraints.maxWidth - 14) / 2;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildFinancialCard(
                      title: 'Total Omzet (Revenue)',
                      amount: finance.totalRevenue,
                      color: AppColors.statusInfo,
                      icon: Icons.payments_outlined,
                      subtext: '+18.4% vs periode lalu',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildFinancialCard(
                      title: 'HPP (Harga Pokok)',
                      amount: finance.totalHpp,
                      color: AppColors.statusWarning,
                      icon: Icons.receipt_long_outlined,
                      subtext: 'Rasio HPP 59.0% (Aman)',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildFinancialCard(
                      title: 'Laba Kotor (Gross)',
                      amount: finance.grossProfit,
                      color: AppColors.chartGreen,
                      icon: Icons.trending_up_rounded,
                      subtext: 'Gross margin 41.0%',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildFinancialCard(
                      title: 'Laba Bersih (Net Profit)',
                      amount: finance.netProfit,
                      color: AppColors.brandLime,
                      isDark: true,
                      icon: Icons.savings_outlined,
                      subtext: 'Net profit margin 27.4%',
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // 3. Middle Section: P&L Breakdown Table & Fund Allocation
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 920) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 13,
                      child: _buildProfitLossCard(finance),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 11,
                      child: _buildFundAllocationCard(finance),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildProfitLossCard(finance),
                    const SizedBox(height: 16),
                    _buildFundAllocationCard(finance),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 20),

          // 4. Bottom Section: Payment Methods Breakdown & Cash in Hand
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 920) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 12,
                      child: _buildPaymentMethodsCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 12,
                      child: _buildCashflowVelocityCard(finance),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPaymentMethodsCard(),
                    const SizedBox(height: 16),
                    _buildCashflowVelocityCard(finance),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required String subtext,
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: AppColors.cardBorder),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMutedOnDark : AppColors.textSecondary,
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
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rp ${_formatRupiah(amount)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.brandLime : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossCard(dynamic finance) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Laporan Laba Rugi (P&L)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Standar SAK EMKM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlRow('Pendapatan Kotor Penjualan', finance.totalRevenue, isPositive: true),
          _buildPlRow('Harga Pokok Penjualan (HPP)', -finance.totalHpp, isNegative: true),
          const Divider(height: 18),
          _buildPlRow('Laba Kotor (Gross Profit)', finance.grossProfit, isBold: true),
          _buildPlRow('Beban Gaji Karyawan', -22000000, isIndent: true),
          _buildPlRow('Sewa Tempat & Utilitas', -11500000, isIndent: true),
          _buildPlRow('Beban Pemasaran & Promo', -5000000, isIndent: true),
          const Divider(height: 18),
          _buildPlRow(
            'Laba Bersih Operasional (Net Profit)',
            finance.netProfit,
            isBold: true,
            highlightColor: AppColors.brandLime,
          ),
        ],
      ),
    );
  }

  Widget _buildPlRow(
    String label,
    double amount, {
    bool isPositive = false,
    bool isNegative = false,
    bool isBold = false,
    bool isIndent = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              isIndent ? '   • $label' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${amount < 0 ? '-' : ''}Rp ${_formatRupiah(amount.abs())}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isNegative
                  ? AppColors.statusDanger
                  : (isPositive
                      ? AppColors.statusSuccess
                      : (isBold ? AppColors.textPrimary : AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundAllocationCard(dynamic finance) {
    return Container(
      padding: const EdgeInsets.all(22),
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
            children: const [
              Expanded(
                child: Text(
                  'Alokasi Dana & Kulakan Stok',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Rekomendasi AI Supri',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.supriOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAllocationBar(
            label: 'Anggaran Kulakan Stok',
            amount: finance.stockRestockBudget,
            percentage: 0.53,
            color: AppColors.supriOrange,
          ),
          const SizedBox(height: 12),
          _buildAllocationBar(
            label: 'Operasional Toko & Shift',
            amount: finance.operationalBudget,
            percentage: 0.27,
            color: AppColors.statusInfo,
          ),
          const SizedBox(height: 12),
          _buildAllocationBar(
            label: 'Dana Cadangan Darurat',
            amount: finance.emergencyReserve,
            percentage: 0.16,
            color: AppColors.chartGreen,
          ),
          const SizedBox(height: 12),
          _buildAllocationBar(
            label: 'Prive / Bagi Hasil',
            amount: finance.profitDraw,
            percentage: 0.04,
            color: AppColors.supriPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationBar({
    required String label,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Rp ${_formatRupiah(amount)} (${(percentage * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsCard() {
    final methods = [
      {'name': 'QRIS (GoPay, OVO, ShopeePay, Dana)', 'share': '45%', 'val': 0.45, 'color': AppColors.statusSuccess},
      {'name': 'Mesin EDC (BCA, Mandiri, BRI)', 'share': '25%', 'val': 0.25, 'color': AppColors.statusInfo},
      {'name': 'Tunai / Cash', 'share': '18%', 'val': 0.18, 'color': const Color(0xFFEAB308)},
      {'name': 'Transfer Virtual Account', 'share': '12%', 'val': 0.12, 'color': AppColors.supriPurple},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metode Pembayaran Kasir',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'QRIS mendominasi 45% dari seluruh transaksi kasir',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...methods.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          m['name'] as String,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        m['share'] as String,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: m['val'] as double,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: AlwaysStoppedAnimation<Color>(m['color'] as Color),
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

  Widget _buildCashflowVelocityCard(dynamic finance) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Kas di Tangan (Cash in Hand)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL LIKUIDITAS SIAP PAKAI',
                      style: TextStyle(fontSize: 10, color: AppColors.textMutedOnDark, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bank + Saldo Kasir POS',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  'Rp ${_formatRupiah(finance.cashInHand)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandLime,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.statusSuccess),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kondisi kas sehat: Dana mampu menutupi operasional & kulakan stok untuk 45 hari ke depan.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
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
