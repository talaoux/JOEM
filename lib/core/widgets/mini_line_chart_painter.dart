import 'package:flutter/material.dart';

import 'package:joem/core/theme/app_colors.dart';

/// Draws a smooth mauve line chart from a list of normalized values
/// (0.0-1.0). Used both as the tiny sparkline inside a [KpiCard] and as
/// the bigger "Évolution des candidatures" chart in the sidebar.
class MiniLineChart extends StatelessWidget {
  const MiniLineChart({
    super.key,
    required this.values,
    this.height = 40,
    this.filled = false,
    this.strokeWidth = 2.5,
  });

  final List<double> values;
  final double height;
  final bool filled;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _MiniLineChartPainter(
          values: values,
          filled: filled,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  _MiniLineChartPainter({
    required this.values,
    required this.filled,
    required this.strokeWidth,
  });

  final List<double> values;
  final bool filled;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * (i / (values.length - 1)),
          size.height * (1 - values[i]),
        ),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final controlX = (current.dx + next.dx) / 2;
      path.cubicTo(controlX, current.dy, controlX, next.dy, next.dx, next.dy);
    }

    if (filled) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.dashboardMauve.withValues(alpha: 0.22),
            AppColors.dashboardMauve.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = AppColors.dashboardMauveDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final lastPointPaint = Paint()..color = AppColors.dashboardMauveDark;
    canvas.drawCircle(points.last, strokeWidth + 1, lastPointPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) =>
      oldDelegate.values != values;
}