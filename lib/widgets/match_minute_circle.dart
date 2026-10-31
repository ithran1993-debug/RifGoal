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
    final double safeMinute = minute.clamp(0, 90).toDouble();

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. الدائرة الخلفية مع خط التقدم الأصفر/الذهبي
          CustomPaint(
            size: const Size(40, 40),
            painter: _MinuteProgressPainter(minute: safeMinute),
          ),

          // 2. كرات الأهداف الخضراء موزعة على محيط الدائرة حسب وقت كل هدف
          ...goalMinutes.map((gMin) {
            final double targetMin = gMin.clamp(1, 90).toDouble();
            // الدقيقة 0 تبدأ من أعلى الدائرة (-pi / 2)، والـ 90 دقيقة تمثل 360 درجة كاملة (2 * pi)
            final double angle = ((targetMin / 90.0) * 2 * math.pi) - (math.pi / 2);
            const double radius = 20.0; // نصف القطر لتقع الكرة تماماً على الخط
            final double dx = radius * math.cos(angle);
            final double dy = radius * math.sin(angle);

            return Transform.translate(
              offset: Offset(dx, dy),
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E222D), // خلفية متناسقة مع الكارت لعزل الكرة
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  size: 11,
                  color: Color(0xFF00E676), // أخضر ساطع مميز للأهداف
                ),
              ),
            );
          }),

          // 3. رقم الدقيقة الحالية في المنتصف
          Text(
            "'$minute",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// كلاس مخصص لرسم مسار الدائرة الرمادي ومسار الدقائق الأصفر
class _MinuteProgressPainter extends CustomPainter {
  final double minute;

  _MinuteProgressPainter({required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // رسم الدائرة الرمادية الأساسية
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);

    // رسم مسار الدقائق باللون الأصفر
    final progressPaint = Paint()
      ..color = const Color(0xFFFFC107) // أصفر ذهبي
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = (minute / 90.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // البداية من أعلى الدائرة
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MinuteProgressPainter oldDelegate) {
    return oldDelegate.minute != minute;
  }
}
