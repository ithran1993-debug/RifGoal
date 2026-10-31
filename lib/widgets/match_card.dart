import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
    // استخراج البيانات سواء كان كائناً أو خريطة
    final String status = _getValue('status') ?? '';
    final bool isLive = status == 'IN_PLAY' || status == 'LIVE';
    final bool isHalfTime = status == 'PAUSED';
    final bool isFinished = status == 'FINISHED';

    final String homeTeam = _getTeamName('homeTeam') ?? 'فريق 1';
    final String awayTeam = _getTeamName('awayTeam') ?? 'فريق 2';
    final String homeCrest = _getTeamCrest('homeTeam') ?? '';
    final String awayCrest = _getTeamCrest('awayTeam') ?? '';

    final dynamic homeScore = _getScore('home');
    final dynamic awayScore = _getScore('away');

    final int currentMinute = _getIntValue('minute') ?? (isHalfTime ? 45 : 31);
    final List<int> goalMinutes = isLive && homeScore != null && awayScore != null && ((homeScore as int? ?? 0) + (awayScore as int? ?? 0) > 0)
        ? [currentMinute]
        : [];

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isLive || isHalfTime) ? Colors.redAccent.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      homeTeam,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCrest(homeCrest),
                ],
              ),
            ),
            SizedBox(
              width: 105,
              child: (isLive || isHalfTime)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${homeScore ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        isHalfTime
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'استراحة',
                                  style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              )
                            : MatchMinuteCircle(
                                minute: currentMinute,
                                goalMinutes: goalMinutes,
                              ),
                        const SizedBox(width: 6),
                        Text(
                          '${awayScore ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : isFinished
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${homeScore ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-', style: TextStyle(color: Colors.grey))),
                            Text('${awayScore ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getTimeString(),
                              style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const Text('VS', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                          ],
                        ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildCrest(awayCrest),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      awayTeam,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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

  dynamic _getValue(String key) {
    if (match is Map) return match[key];
    try {
      if (key == 'status') return match.status;
    } catch (_) {}
    return null;
  }

  int? _getIntValue(String key) {
    if (match is Map) return match[key] as int?;
    try {
      if (key == 'minute') return match.minute as int?;
    } catch (_) {}
    return null;
  }

  String? _getTeamName(String key) {
    if (match is Map) return match[key]?['name'];
    try {
      if (key == 'homeTeam') return match.homeTeam?.name ?? match.homeTeamName;
      if (key == 'awayTeam') return match.awayTeam?.name ?? match.awayTeamName;
    } catch (_) {}
    return null;
  }

  String? _getTeamCrest(String key) {
    if (match is Map) return match[key]?['crest'];
    try {
      if (key == 'homeTeam') return match.homeTeam?.crest ?? match.homeTeamCrest;
      if (key == 'awayTeam') return match.awayTeam?.crest ?? match.awayTeamCrest;
    } catch (_) {}
    return null;
  }

  dynamic _getScore(String side) {
    if (match is Map) return match['score']?['fullTime']?[side] ?? match['score']?['current']?[side];
    try {
      if (side == 'home') return match.score?.fullTime?.home ?? match.homeScore;
      if (side == 'away') return match.score?.fullTime?.away ?? match.awayScore;
    } catch (_) {}
    return null;
  }

  String _getTimeString() {
    if (match is Map) {
      if (match['utcDate'] != null) return match['utcDate'].toString().substring(11, 16);
      return match['time'] ?? '15:00';
    }
    try {
      if (match.utcDate != null) return match.utcDate.toString().substring(11, 16);
      if (match.time != null) return match.time.toString();
    } catch (_) {}
    return '15:00';
  }

  Widget _buildCrest(String url) {
    if (url.isEmpty) {
      return const CircleAvatar(radius: 12, backgroundColor: Colors.transparent, child: Icon(Icons.sports_soccer, size: 20, color: AppColors.muted));
    }
    return Image.network(
      url,
      width: 24,
      height: 24,
      errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 20, color: AppColors.muted),
    );
  }
}
