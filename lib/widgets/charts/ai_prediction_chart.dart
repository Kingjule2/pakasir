import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AiPredictionChart extends StatelessWidget {
  const AiPredictionChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: CustomPaint(
        painter: _AiPredictionPainter(),
      ),
    );
  }
}

class _AiPredictionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle horizontal guidelines
    final linePaint = Paint()
      ..color = const Color(0xFFF1F3F5)
      ..strokeWidth = 1.0;

    const count = 3;
    for (int i = 0; i <= count; i++) {
      final y = (size.height / count) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // 2. Actual Sales curve (subtle dotted/solid grey-green)
    final actualPoints = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.25, size.height * 0.65),
      Offset(size.width * 0.50, size.height * 0.70),
      Offset(size.width * 0.75, size.height * 0.45),
      Offset(size.width, size.height * 0.35),
    ];

    final actualPath = _buildSpline(actualPoints);
    final actualPaint = Paint()
      ..color = const Color(0xFFB0B7C3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(actualPath, actualPaint);

    // 3. AI Prediction curve (smooth rising vibrant green line)
    final aiPoints = [
      Offset(0, size.height * 0.82),
      Offset(size.width * 0.25, size.height * 0.70),
      Offset(size.width * 0.50, size.height * 0.60),
      Offset(size.width * 0.75, size.height * 0.28),
      Offset(size.width, size.height * 0.12),
    ];

    final aiPath = _buildSpline(aiPoints);

    // Fill underneath
    final aiFill = Path.from(aiPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.statusSuccess.withValues(alpha: 0.25),
          AppColors.statusSuccess.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(aiFill, fillPaint);

    final aiPaint = Paint()
      ..color = AppColors.statusSuccess
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(aiPath, aiPaint);

    // End point highlight dot
    final endPoint = aiPoints.last;
    canvas.drawCircle(
      endPoint,
      4.0,
      Paint()..color = AppColors.statusSuccess,
    );
    canvas.drawCircle(
      endPoint,
      2.0,
      Paint()..color = Colors.white,
    );
  }

  Path _buildSpline(List<Offset> points) {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
