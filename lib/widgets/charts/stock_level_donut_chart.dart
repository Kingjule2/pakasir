import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StockLevelDonutChartCard extends StatelessWidget {
  final int inStock;
  final int lowStock;
  final int outOfStock;

  const StockLevelDonutChartCard({
    super.key,
    this.inStock = 52,
    this.lowStock = 25,
    this.outOfStock = 23,
  });

  @override
  Widget build(BuildContext context) {
    final total = inStock + lowStock + outOfStock;
    final inStockPct = total > 0 ? ((inStock / total) * 100).round() : 0;
    final lowStockPct = total > 0 ? ((lowStock / total) * 100).round() : 0;
    final outOfStockPct = max(0, 100 - inStockPct - lowStockPct);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tingkat Ketersediaan Stok',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Current inventory ratio breakdown (Stitch Design)',
                    style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tableHeaderBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Stitch Donut',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(110, 110),
                      painter: _StitchDonutPainter(
                        inStockRatio: inStockPct / 100.0,
                        lowStockRatio: lowStockPct / 100.0,
                        outOfStockRatio: outOfStockPct / 100.0,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$inStockPct%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryNavy,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'In Stock',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendRow(
                      color: AppColors.primaryNavy,
                      label: 'In Stock (Aman)',
                      value: '$inStockPct%',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendRow(
                      color: AppColors.accentSkyBlue,
                      label: 'Low Stock (<30)',
                      value: '$lowStockPct%',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendRow(
                      color: const Color(0xFFE8EEFB),
                      label: 'Out of Stock',
                      value: '$outOfStockPct%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.borderSubtle, width: 0.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _StitchDonutPainter extends CustomPainter {
  final double inStockRatio;
  final double lowStockRatio;
  final double outOfStockRatio;

  _StitchDonutPainter({
    required this.inStockRatio,
    required this.lowStockRatio,
    required this.outOfStockRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 14.0;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFF1F3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    double startAngle = -pi / 2;

    // 1. In Stock: Navy #0F0F4A
    final sweep1 = 2 * pi * inStockRatio;
    final paint1 = Paint()
      ..color = AppColors.primaryNavy
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep1, false, paint1);
    startAngle += sweep1;

    // 2. Low Stock: Sky Blue #B9D9FA
    final sweep2 = 2 * pi * lowStockRatio;
    final paint2 = Paint()
      ..color = AppColors.accentSkyBlue
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep2, false, paint2);
    startAngle += sweep2;

    // 3. Out of Stock: Pale Periwinkle #E8EEFB
    final sweep3 = 2 * pi * outOfStockRatio;
    final paint3 = Paint()
      ..color = const Color(0xFFE8EEFB)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep3, false, paint3);
  }

  @override
  bool shouldRepaint(covariant _StitchDonutPainter oldDelegate) {
    return oldDelegate.inStockRatio != inStockRatio ||
        oldDelegate.lowStockRatio != lowStockRatio ||
        oldDelegate.outOfStockRatio != outOfStockRatio;
  }
}
