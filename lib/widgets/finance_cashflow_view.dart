import 'package:flutter/material.dart';
import '../models/financial_summary.dart';
import '../theme/app_colors.dart';

class FinanceCashflowView extends StatelessWidget {
  final FinancialSummary finance;
  final VoidCallback onBackToInventory;

  const FinanceCashflowView({
    super.key,
    required this.finance,
    required this.onBackToInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView(
        children: [
          // Banner / Back Button
          Row(
            children: [
              IconButton(
                onPressed: onBackToInventory,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Inventory',
              ),
              const SizedBox(width: 8),
              const Text(
                'Cash Flow & Profit Tracking (Memory Engine)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Core Financial KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  title: 'Total Omzet (Revenue)',
                  amount: finance.totalRevenue,
                  color: AppColors.statusInfo,
                  icon: Icons.payments_outlined,
                  subtext: '+18.4% vs bulan lalu',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFinancialCard(
                  title: 'HPP (Harga Pokok)',
                  amount: finance.totalHpp,
                  color: AppColors.statusWarning,
                  icon: Icons.receipt_long_outlined,
                  subtext: 'Rasio HPP: 59% aman',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFinancialCard(
                  title: 'Laba Kotor (Gross)',
                  amount: finance.grossProfit,
                  color: AppColors.chartGreen,
                  icon: Icons.trending_up_rounded,
                  subtext: 'Margin kotor 41%',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFinancialCard(
                  title: 'Laba Bersih (Net Profit)',
                  amount: finance.netProfit,
                  color: AppColors.brandLime,
                  isDark: true,
                  icon: Icons.savings_outlined,
                  subtext: 'Margin bersih 27.4%',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Distribusi Alokasi Dana (Blueprint Section 2)
          Container(
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
                      'Distribusi Dana Operasional & Kulakan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Rekomendasi AI Supri',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.supriOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAllocationBar(
                  label: 'Dana Kulakan / Restock Buffer (53%)',
                  amount: finance.stockRestockBudget,
                  percentage: 0.53,
                  color: AppColors.brandLime,
                ),
                const SizedBox(height: 12),
                _buildAllocationBar(
                  label: 'Biaya Operasional & Gaji (26%)',
                  amount: finance.operationalBudget,
                  percentage: 0.26,
                  color: AppColors.statusInfo,
                ),
                const SizedBox(height: 12),
                _buildAllocationBar(
                  label: 'Cadangan Darurat / Kas Mengendap (16%)',
                  amount: finance.emergencyReserve,
                  percentage: 0.16,
                  color: AppColors.statusWarning,
                ),
                const SizedBox(height: 12),
                _buildAllocationBar(
                  label: 'Dividen Owner / Profit Draw (5%)',
                  amount: finance.profitDraw,
                  percentage: 0.05,
                  color: AppColors.supriOrange,
                ),
              ],
            ),
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textMutedOnDark : AppColors.textMuted,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rp ${(amount / 1000000).toStringAsFixed(1)} Jt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.brandLime : color,
            ),
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Rp ${(amount / 1000000).toStringAsFixed(1)} Juta',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            backgroundColor: const Color(0xFFF1F3F5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
