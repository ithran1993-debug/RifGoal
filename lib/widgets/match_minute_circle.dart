import 'dart:math' as math;
import 'package:flutter/material.dart';

class MatchMinuteCircle extends StatelessWidget {
  final int minute; // الدقيقة الحالية للمباراة (تحدد نهاية القوس الأصفر)
  final List<int> goalMinutes; // قائمة دقائق كل الأهداف المسجلة (مثلاً: [12, 28, 75])

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
          // 1. الدائرة الأساسية + القوس الأصفر الذي يدور مع دقيقة المباراة الحالية
          CustomPaint(
            size: const Size(40, 40),
            painter: _MinuteProgressPainter(currentMinute: safeMinute),
          ),

          // 2. كرات الأهداف: كل كرة تثبت في مكان الدقيقة التي سجل فيها الهدف
          ...goalMinutes.map((goalMin) {
            // حساب زاوية كل هدف: 90 دقيقة = دورة كاملة (2 * pi)، البداية من أعلى الدائرة (-pi / 2)
            final double clampedGoal = goalMin.clamp(1, 90).toDouble();
            final double goalAngle = ((clampedGoal / 90.0) * 2 * math.pi) - (math.pi / 2);
            
            const double radius = 20.0; // نصف القطر لتوضع الكرة مباشرة فوق خط الدائرة
            final double dx = radius * math.cos(goalAngle);
            final double dy = radius * math.sin(goalAngle);

            return Transform.translate(
              offset: Offset(dx, dy),
              child: Container(
                width: 13,
                height: 13,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E222D), // عازل خلفي بلون بطاقة المباراة
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.sports_soccer,
                    size: 11,
                    color: Color(0xFF00E676), // الكرة باللون الأخضر الساطع
                  ),
                ),
              ),
            );
          }),

          // 3. عرض رقم الدقيقة الحالية للمباراة في المنتصف
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

class _MinuteProgressPainter extends CustomPainter {
  final double currentMinute;

  _MinuteProgressPainter({required this.currentMinute});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // مسار الدائرة الرمادي (المتبقي من الـ 90 دقيقة)
    final bgPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // مسار اللون الأصفر الذي يدور بحسب توقيت المباراة الفعلي
    if (currentMinute > 0) {
      final progressPaint = Paint()
        ..color = const Color(0xFFFFC107) // أصفر ذهبي واضح
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
  }

  @override
  bool shouldRepaint(covariant _MinuteProgressPainter oldDelegate) {
    return oldDelegate.currentMinute != currentMinute;
  }
}
