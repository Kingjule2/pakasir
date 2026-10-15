import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StockVolumeChart extends StatefulWidget {
  final String activeTimeframe;
  final ValueChanged<String> onTimeframeChanged;

  const StockVolumeChart({
    super.key,
    required this.activeTimeframe,
    required this.onTimeframeChanged,
  });

  @override
  State<StockVolumeChart> createState() => _StockVolumeChartState();
}

class _StockVolumeChartState extends State<StockVolumeChart> {
  int _selectedCategoryIndex = 3; // Default to 'Fashion' matching Image #1

  final List<String> _categories = [
    'Electronic',
    'Drinks',
    'Watch',
    'Fashion',
    'Toys',
    'Home',
  ];

  // Values in thousands ($K) for Stock Volume
  final List<double> _stockVolume = [22.0, 34.0, 28.0, 42.0, 31.0, 36.0];
  // Values in thousands ($K) for Consume Rate
  final List<double> _consumeRate = [16.0, 24.0, 20.0, 26.0, 22.0, 25.0];

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Total Stock Volume vs Consume Rate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // Legend
              _buildLegendDot(AppColors.brandLime, 'Stock volume'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFFA1BC20), 'Consume'),
              const SizedBox(width: 16),
              // Timeframe dropdown
              _buildTimeframeDropdown(),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Canvas with Interactive Tooltip
          SizedBox(
            height: 190,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    final widthPerCategory =
                        constraints.maxWidth / _categories.length;
                    final clickedIndex =
                        (details.localPosition.dx / widthPerCategory)
                            .floor()
                            .clamp(0, _categories.length - 1);
                    setState(() {
                      _selectedCategoryIndex = clickedIndex;
                    });
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Grid & Spline Area Painter
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SplineChartPainter(
                            stockData: _stockVolume,
                            consumeData: _consumeRate,
                            selectedIndex: _selectedCategoryIndex,
                            maxY: 50.0,
                          ),
                        ),
                      ),

                      // Tooltip over selected category
                      _buildFloatingTooltip(constraints.maxWidth),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // X-Axis Categories
          Row(
            children: List.generate(_categories.length, (index) {
              final isSelected = index == _selectedCategoryIndex;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cardDark
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categories[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.activeTimeframe,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: const [
            DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
            DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'Daily', child: Text('Daily')),
          ],
          onChanged: (val) {
            if (val != null) widget.onTimeframeChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildFloatingTooltip(double maxWidth) {
    final stepX = maxWidth / (_categories.length - 1);
    final targetX = stepX * _selectedCategoryIndex;
    final selectedVal = _stockVolume[_selectedCategoryIndex];

    // Compute Y in chart (range 0 to 50k, canvas height 190, leaving 20px bottom padding)
    final chartHeight = 170.0;
    final ratioY = (selectedVal / 50.0).clamp(0.0, 1.0);
    final targetY = chartHeight - (ratioY * chartHeight);

    final displayAmount =
        _selectedCategoryIndex == 3 ? '31,000' : '${(selectedVal * 1000).toInt()}';

    return Positioned(
      left: (targetX - 44).clamp(8.0, maxWidth - 96.0),
      top: (targetY - 54).clamp(0.0, 120.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tooltipDark,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Stock In',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textMutedOnDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$ $displayAmount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandLime,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          // Down arrow triangle
          CustomPaint(
            size: const Size(8, 5),
            painter: _TrianglePainter(color: AppColors.tooltipDark),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => false;
}

class _SplineChartPainter extends CustomPainter {
  final List<double> stockData;
  final List<double> consumeData;
  final int selectedIndex;
  final double maxY;

  _SplineChartPainter({
    required this.stockData,
    required this.consumeData,
    required this.selectedIndex,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 38.0;
    final chartWidth = size.width - leftMargin;
    const chartHeight = 160.0;

    // 1. Draw horizontal grid lines and Y-axis labels ($50K, $40K, $30K, $20K, $10K)
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F3F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const yLevels = [50, 40, 30, 20, 10];
    for (final level in yLevels) {
      final y = chartHeight - ((level / maxY) * chartHeight);

      // Grid line
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Label
      textPainter.text = TextSpan(
        text: '\$${level}K',
        style: const TextStyle(
          color: Color(0xFFB0B5BD),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    if (stockData.length < 2) return;

    // 2. Build points for stock data
    final stockPoints = <Offset>[];
    final stepX = chartWidth / (stockData.length - 1);
    for (int i = 0; i < stockData.length; i++) {
      final x = leftMargin + (i * stepX);
      final y = chartHeight - ((stockData[i] / maxY) * chartHeight);
      stockPoints.add(Offset(x, y));
    }

    // Build points for consume data
    final consumePoints = <Offset>[];
    for (int i = 0; i < consumeData.length; i++) {
      final x = leftMargin + (i * stepX);
      final y = chartHeight - ((consumeData[i] / maxY) * chartHeight);
      consumePoints.add(Offset(x, y));
    }

    // 3. Draw Consume line (softer line)
    final consumePath = _createSmoothSpline(consumePoints);
    final consumePaint = Paint()
      ..color = const Color(0xFFA1BC20).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(consumePath, consumePaint);

    // 4. Draw Stock Volume gradient fill
    final stockPath = _createSmoothSpline(stockPoints);

    final fillPath = Path.from(stockPath)
      ..lineTo(stockPoints.last.dx, chartHeight)
      ..lineTo(stockPoints.first.dx, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.brandLime.withValues(alpha: 0.35),
          AppColors.brandLime.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw Stock Volume line (lime green)
    final stockLinePaint = Paint()
      ..color = AppColors.brandLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(stockPath, stockLinePaint);

    // 6. Selected indicator dot
    if (selectedIndex >= 0 && selectedIndex < stockPoints.length) {
      final sel = stockPoints[selectedIndex];

      // Vertical dashed guide line
      final guidePaint = Paint()
        ..color = AppColors.brandLime.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(sel.dx, sel.dy), Offset(sel.dx, chartHeight), guidePaint);

      // Outer ring
      final outerPaint = Paint()
        ..color = AppColors.brandLime
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sel, 6.0, outerPaint);

      // Inner dot
      final innerPaint = Paint()
        ..color = AppColors.tooltipDark
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sel, 3.0, innerPaint);
    }
  }

  Path _createSmoothSpline(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;

      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.stockData != stockData;
  }
}
