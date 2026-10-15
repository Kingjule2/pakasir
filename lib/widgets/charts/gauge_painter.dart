import 'dart:math' as math;
import 'package:flutter/material.dart';

class SemiCircleGauge extends StatelessWidget {
  final double percentage; // 0.0 to 1.0
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;
  final String centerLabel;
  final String? centerSub;
  final double size;

  const SemiCircleGauge({
    super.key,
    required this.percentage,
    required this.activeColor,
    this.trackColor = const Color(0xFFF1F3F5),
    this.strokeWidth = 6.0,
    required this.centerLabel,
    this.centerSub,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.75,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size * 0.65),
            painter: _GaugePainter(
              percentage: percentage.clamp(0.0, 1.0),
              activeColor: activeColor,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Positioned(
            bottom: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF14171A),
                    height: 1.1,
                  ),
                ),
                if (centerSub != null)
                  Text(
                    centerSub!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8F959E),
                      height: 1.0,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  _GaugePainter({
    required this.percentage,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = math.pi; // 180 deg
    const sweepAngle = math.pi; // 180 deg sweep

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Draw active arc
    if (percentage > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * percentage,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.activeColor != activeColor;
  }
}
