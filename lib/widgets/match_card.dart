import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import 'match_minute_circle.dart';

class MatchCard extends StatefulWidget {
  final Match match;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  List<int> _realGoalMinutes = [];

  @override
  void initState() {
    super.initState();
    _fetchGoalsIfLive();
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.score != widget.match.score) {
      _fetchGoalsIfLive();
    }
  }

  void _fetchGoalsIfLive() {
    // جلب دقائق الأهداف الحقيقية إذا كانت المباراة جارية وفيها أهداف
    final isLive = widget.match.statusClass == 'live' || widget.match.statusClass == 'half';
    if (isLive && widget.match.score.contains('-')) {
      final parts = widget.match.score.split('-');
      final homeGoals = int.tryParse(parts[0].trim()) ?? 0;
      final awayGoals = int.tryParse(parts[1].trim()) ?? 0;

      if ((homeGoals + awayGoals) > 0) {
        MatchService.getRealGoalMinutes(widget.match.id).then((minutes) {
          if (mounted && minutes.isNotEmpty) {
            setState(() {
              _realGoalMinutes = minutes;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final bool isLive = match.statusClass == 'live';
    final bool isHalfTime = match.statusClass == 'half';
    final bool isFinished = match.statusClass == 'finished';

    // استخراج الدقيقة الحية الحقيقية القادمة من السيرفر
    int minute = 1;
    if (match.minute != null) {
      minute = int.tryParse(match.minute!.replaceAll("'", "")) ?? 1;
    } else if (isHalfTime) {
      minute = 45;
    }

    // تقسيم النتيجة
    int? homeScore;
    int? awayScore;
    if (match.score.contains('-')) {
      final parts = match.score.split('-');
      homeScore = int.tryParse(parts[0].trim());
      awayScore = int.tryParse(parts[1].trim());
    }

    // إذا لم تكتمل استجابة جلب الدقائق بعد، نستخدم توزيعاً دقيقاً مؤقتاً
    List<int> goalMinutes = _realGoalMinutes;
    final int totalGoals = (homeScore ?? 0) + (awayScore ?? 0);
    if (goalMinutes.isEmpty && totalGoals > 0 && isLive) {
      goalMinutes = [];
      for (int i = 1; i <= totalGoals; i++) {
        goalMinutes.add(((minute / (totalGoals + 1)) * i).round().clamp(1, 89));
      }
    }

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isLive || isHalfTime)
                ? Colors.redAccent.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // فريق المضيف (اليمين)
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      match.home.name.isNotEmpty ? match.home.name : 'المضيف',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCrest(match.home.logo),
                ],
              ),
            ),

            // منطقة الوسط (النتيجة / الدائرة التفاعلية / الوقت)
            SizedBox(
              width: 105,
              child: isLive
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${homeScore ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        MatchMinuteCircle(
                          minute: minute,
                          goalMinutes: goalMinutes,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${awayScore ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : isHalfTime
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${homeScore ?? 0}',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'استراحة',
                                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${awayScore ?? 0}',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : isFinished
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${homeScore ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('-', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                ),
                                Text('${awayScore ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  match.status,
                                  style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const Text('VS', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                              ],
                            ),
            ),

            // فريق الضيف (اليسار)
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildCrest(match.away.logo),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      match.away.name.isNotEmpty ? match.away.name : 'الضيف',
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrest(String url) {
    if (url.isEmpty) {
      return const CircleAvatar(
        radius: 12,
        backgroundColor: Colors.transparent,
        child: Icon(Icons.sports_soccer, size: 20, color: AppColors.muted),
      );
    }
    return Image.network(
      url,
      width: 24,
      height: 24,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.sports_soccer,
        size: 20,
        color: AppColors.muted,
      ),
    );
  }
}
