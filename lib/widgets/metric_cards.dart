import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'charts/gauge_painter.dart';

class MetricCardsGrid extends StatelessWidget {
  const MetricCardsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive columns: 4 for wide screens, 2 for tablet/medium, 1 for mobile
        if (constraints.maxWidth > 900) {
          return Row(
            children: [
              Expanded(child: _buildTotalOrdersCard()),
              const SizedBox(width: 14),
              Expanded(child: _buildAlreadyDeliveredCard()),
              const SizedBox(width: 14),
              Expanded(child: _buildProductReturnCard()),
              const SizedBox(width: 14),
              Expanded(child: _buildTurnoverRateCard()),
            ],
          );
        } else if (constraints.maxWidth > 550) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildTotalOrdersCard()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildAlreadyDeliveredCard()),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildProductReturnCard()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildTurnoverRateCard()),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildTotalOrdersCard(),
              const SizedBox(height: 12),
              _buildAlreadyDeliveredCard(),
              const SizedBox(height: 12),
              _buildProductReturnCard(),
              const SizedBox(height: 12),
              _buildTurnoverRateCard(),
            ],
          );
        }
      },
    );
  }

  // 1. Total Orders Card (Dark card)
  Widget _buildTotalOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brandLime.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 17,
                  color: AppColors.brandLime,
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: AppColors.textMutedOnDark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Total Orders',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMutedOnDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '2,580',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '+12%',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusSuccess,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Since Last Month',
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textMutedOnDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Already Delivered Card (White card)
  Widget _buildAlreadyDeliveredCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 17,
                  color: Color(0xFFEAB308),
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Already Delivered',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '2,380',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '+7%',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusSuccess,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Since Last Month',
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Product Return Card (White card with gauge)
  Widget _buildProductReturnCard() {
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brandLime.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_return_outlined,
              size: 17,
              color: Color(0xFF9EBA28),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Product Return',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '10%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '-10%',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Since last month',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SemiCircleGauge(
                percentage: 0.65,
                activeColor: Color(0xFFEAB308),
                centerLabel: '120',
                centerSub: 'Return',
                size: 68,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Turnover Rate Card (White card with gauge)
  Widget _buildTurnoverRateCard() {
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6E91).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.speed_rounded,
              size: 17,
              color: Color(0xFFFF4E78),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Turnover Rate',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2.5 Days',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '-20%',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Since last month',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SemiCircleGauge(
                percentage: 0.40,
                activeColor: Color(0xFFFF4E78),
                centerLabel: '20%',
                centerSub: 'Decrease',
                size: 68,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
