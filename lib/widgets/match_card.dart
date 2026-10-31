import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import 'match_minute_circle.dart';

class MatchCard extends StatelessWidget {
  final dynamic match;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. استخراج حالة المباراة
    final String status = _extractStatus().toUpperCase();
    final bool isLive = status == 'IN_PLAY' || status == 'LIVE' || status == 'IN PLAY';
    final bool isHalfTime = status == 'PAUSED' || status == 'HT' || status == 'HALF';
    final bool isFinished = status == 'FINISHED' || status == 'FT';

    // 2. استخراج أسماء الفرق مع التعريب
    final String rawHome = _extractTeamName('home');
    final String rawAway = _extractTeamName('away');
    final String homeTeam = AppConstants.translateTeam(rawHome);
    final String awayTeam = AppConstants.translateTeam(rawAway);

    // 3. استخراج الشعارات
    final String homeCrest = _extractCrest('home');
    final String awayCrest = _extractCrest('away');

    // 4. استخراج النتيجة
    final int? homeScore = _extractScore('home');
    final int? awayScore = _extractScore('away');

    // 5. استخراج الدقيقة ودقائق الأهداف بدقة
    final int minute = _extractMinute(isHalfTime);
    final List<int> goalMinutes = _extractGoalMinutes(isLive, homeScore, awayScore, minute);

    return InkWell(
      onTap: onTap,
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
                      homeTeam.isNotEmpty ? homeTeam : 'المضيف',
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
                  _buildCrest(homeCrest),
                ],
              ),
            ),

            // منطقة الوسط (النتيجة / الدائرة / وقت اللقاء)
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
                                  _extractTime(),
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
                  _buildCrest(awayCrest),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      awayTeam.isNotEmpty ? awayTeam : 'الضيف',
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

  // --- دوال تحليل البيانات واستخراج الدقيقة بدقة ---

  String _extractStatus() {
    if (match is Map) {
      return (match['status'] ?? match['statusClass'] ?? '').toString();
    }
    try {
      return (match.statusClass ?? match.status ?? '').toString();
    } catch (_) {}
    return '';
  }

  String _extractTeamName(String side) {
    if (match is Map) {
      if (side == 'home') {
        return (match['homeTeam']?['name'] ?? match['homeTeam']?['shortName'] ?? match['home']?['name'] ?? match['home'] ?? '').toString();
      } else {
        return (match['awayTeam']?['name'] ?? match['awayTeam']?['shortName'] ?? match['away']?['name'] ?? match['away'] ?? '').toString();
      }
    }
    try {
      if (side == 'home') return match.home?.name ?? match.homeTeam?.name ?? '';
      if (side == 'away') return match.away?.name ?? match.awayTeam?.name ?? '';
    } catch (_) {}
    return '';
  }

  String _extractCrest(String side) {
    if (match is Map) {
      if (side == 'home') {
        return (match['homeTeam']?['crest'] ?? match['home']?['logo'] ?? match['homeCrest'] ?? '').toString();
      } else {
        return (match['awayTeam']?['crest'] ?? match['away']?['logo'] ?? match['awayCrest'] ?? '').toString();
      }
    }
    try {
      if (side == 'home') return match.home?.logo ?? match.homeTeam?.crest ?? '';
      if (side == 'away') return match.away?.logo ?? match.awayTeam?.crest ?? '';
    } catch (_) {}
    return '';
  }

  int? _extractScore(String side) {
    if (match is Map) {
      final scoreObj = match['score'];
      if (scoreObj is Map) {
        final ft = scoreObj['fullTime'];
        if (ft is Map && ft[side] != null) return int.tryParse(ft[side].toString());
        if (scoreObj['current'] is Map && scoreObj['current'][side] != null) {
          return int.tryParse(scoreObj['current'][side].toString());
        }
      }
      final rawScore = match['score']?.toString();
      if (rawScore != null && rawScore.contains('-')) {
        final parts = rawScore.split('-');
        if (side == 'home') return int.tryParse(parts[0].trim());
        if (side == 'away') return int.tryParse(parts[1].trim());
      }
    }
    try {
      if (match.score is String && match.score.contains('-')) {
        final parts = match.score.split('-');
        return side == 'home' ? int.tryParse(parts[0].trim()) : int.tryParse(parts[1].trim());
      }
    } catch (_) {}
    return null;
  }

  int _extractMinute(bool isHalfTime) {
    if (isHalfTime) return 45;

    // 1. فحص إذا كانت الدقيقة قادمة من الـ API
    if (match is Map && match['minute'] != null) {
      final parsed = int.tryParse(match['minute'].toString().replaceAll("'", ""));
      if (parsed != null && parsed > 0) return parsed;
    }
    try {
      if (match.minute != null) {
        final parsed = int.tryParse(match.minute.toString().replaceAll("'", ""));
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (_) {}

    // 2. الحساب الزمني الديناميكي بناءً على وقت انطلاق المباراة (utcDate)
    DateTime? startTime;
    if (match is Map && match['utcDate'] != null) {
      startTime = DateTime.tryParse(match['utcDate'].toString());
    } else {
      try {
        startTime = match.date;
      } catch (_) {}
    }

    if (startTime != null) {
      final nowUtc = DateTime.now().toUtc();
      final diffInMin = nowUtc.difference(startTime.toUtc()).inMinutes;

      if (diffInMin > 0) {
        if (diffInMin <= 45) return diffInMin;
        if (diffInMin <= 60) return 45; // استراحة بين الشوطين
        final secondHalfMin = diffInMin - 15;
        return secondHalfMin.clamp(46, 90);
      }
    }

    return 1;
  }

  List<int> _extractGoalMinutes(bool isLive, int? homeScore, int? awayScore, int currentMin) {
    // 1. إذا كانت الـ API توفر مصفوفة تفاصيل الأهداف
    if (match is Map) {
      if (match['goals'] is List && (match['goals'] as List).isNotEmpty) {
        return (match['goals'] as List)
            .map((g) => int.tryParse((g['minute'] ?? currentMin).toString()) ?? currentMin)
            .toList();
      }
      if (match['goalMinutes'] is List && (match['goalMinutes'] as List).isNotEmpty) {
        return (match['goalMinutes'] as List)
            .map((m) => int.tryParse(m.toString()) ?? currentMin)
            .toList();
      }
    }

    // 2. توزيع الأهداف المسجلة في دقائق مختلفة على مسار الـ 90 دقيقة
    final int totalGoals = (homeScore ?? 0) + (awayScore ?? 0);
    if (totalGoals > 0) {
      final List<int> minutes = [];
      for (int i = 1; i <= totalGoals; i++) {
        // وضع كل هدف في دقيقة منفصلة سابقة للدقيقة الحالية لتظهر كل كرة في زاويتها الخاصة
        final int target = ((currentMin / (totalGoals + 1)) * i).round().clamp(1, 89);
        minutes.add(target);
      }
      return minutes;
    }

    return [];
  }

  String _extractTime() {
    if (match is Map) {
      if (match['utcDate'] != null) {
        try {
          final dt = DateTime.parse(match['utcDate'].toString()).toLocal();
          final h = dt.hour.toString().padLeft(2, '0');
          final m = dt.minute.toString().padLeft(2, '0');
          return '$h:$m';
        } catch (_) {}
      }
      return match['time'] ?? '15:00';
    }
    try {
      if (match.date != null) {
        final dt = match.date as DateTime;
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      if (match.status != null) return match.status.toString();
    } catch (_) {}
    return '15:00';
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
