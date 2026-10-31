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
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
            ),
          ),
          ...goalMinutes.map((gMin) {
            final double angle = ((gMin.clamp(1, 90) / 90.0) * 2 * math.pi) - (math.pi / 2);
            const double radius = 19.0;
            final double dx = radius * math.cos(angle);
            final double dy = radius * math.sin(angle);

            return Transform.translate(
              offset: Offset(dx, dy),
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  size: 11,
                  color: Colors.green,
                ),
              ),
            );
          }),
          Text(
            "'$minute",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
