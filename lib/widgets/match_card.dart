import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import 'match_minute_circle.dart';

class MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final VoidCallback? onTap;

  const MatchCard({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = match['status'] ?? '';
    final bool isLive = status == 'IN_PLAY' || status == 'LIVE';
    final bool isHalfTime = status == 'PAUSED';
    final bool isFinished = status == 'FINISHED';

    final homeNameRaw = match['homeTeam']?['name'] ?? '';
    final awayNameRaw = match['awayTeam']?['name'] ?? '';
    final homeTeam = AppConstants.translateTeam(homeNameRaw);
    final awayTeam = AppConstants.translateTeam(awayNameRaw);

    final homeCrest = match['homeTeam']?['crest'] ?? '';
    final awayCrest = match['awayTeam']?['crest'] ?? '';

    final homeScore = match['score']?['fullTime']?['home'] ?? match['score']?['current']?['home'];
    final awayScore = match['score']?['fullTime']?['away'] ?? match['score']?['current']?['away'];

    final int currentMinute = match['minute'] ?? (isHalfTime ? 45 : 31);
    final List<int> goalMinutes = (match['goalMinutes'] as List?)?.map((e) => e as int).toList() ??
        ((homeScore != null && (homeScore + (awayScore ?? 0) > 0)) ? [currentMinute] : []);

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
            // الفريق الأول
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

            // منطقة المنتصف
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
                              match['utcDate'] != null
                                  ? match['utcDate'].toString().substring(11, 16)
                                  : (match['time'] ?? '15:00'),
                              style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const Text('VS', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                          ],
                        ),
            ),

            // الفريق الثاني
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
