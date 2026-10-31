import 'dart:math' as math;
import 'package:flutter/material.dart';

class MatchMinuteCircle extends StatelessWidget {
  final int minute;
  final List<int> goalMinutes;

  const MatchMinuteCircle({
    super.key,
    required this.minute,
    this.goalMinutes = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _MatchCirclePainter(
          currentMinute: minute.clamp(0, 90).toDouble(),
          goalMinutes: goalMinutes,
        ),
        child: Center(
          child: Text(
            "'$minute",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCirclePainter extends CustomPainter {
  final double currentMinute;
  final List<int> goalMinutes;

  _MatchCirclePainter({
    required this.currentMinute,
    required this.goalMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 20.0;

    // 1. الدائرة الرمادية الأساسية
    final trackPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. خط التقدم الأصفر يدور بحسب وقت المباراة
    if (currentMinute > 0) {
      final progressPaint = Paint()
        ..color = const Color(0xFFFFC107)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final double sweepAngle = (currentMinute / 90.0) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // البداية من أعلى الدائرة (الدقيقة 0)
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // 3. رسم كرات الأهداف في مواضعها الزمنية الدقيقة على محيط الـ 90 دقيقة
    for (final gMin in goalMinutes) {
      final double target = gMin.clamp(1, 90).toDouble();
      final double angle = ((target / 90.0) * 2 * math.pi) - (math.pi / 2);
      final double gx = center.dx + radius * math.cos(angle);
      final double gy = center.dy + radius * math.sin(angle);
      final goalCenter = Offset(gx, gy);

      // دائرة خلفية داكنة لعزل الكرة
      final bgGoalPaint = Paint()
        ..color = const Color(0xFF1E222D)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(goalCenter, 5.0, bgGoalPaint);

      // كرة الهدف باللون الأخضر
      final greenPaint = Paint()
        ..color = const Color(0xFF00E676)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(goalCenter, 3.8, greenPaint);

      // إطار خفيف للكرة
      final strokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(goalCenter, 3.8, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MatchCirclePainter oldDelegate) {
    return oldDelegate.currentMinute != currentMinute ||
        oldDelegate.goalMinutes != goalMinutes;
  }
}
