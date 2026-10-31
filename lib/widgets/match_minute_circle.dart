import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'match_minute_circle.dart';

class MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = match['status'] ?? '';
    final bool isLive = status == 'IN_PLAY' || status == 'LIVE' || status == 'PAUSED';
    final bool isFinished = status == 'FINISHED';

    final homeTeam = match['homeTeam']?['name'] ?? 'فريق 1';
    final awayTeam = match['awayTeam']?['name'] ?? 'فريق 2';
    final homeCrest = match['homeTeam']?['crest'] ?? '';
    final awayCrest = match['awayTeam']?['crest'] ?? '';

    final homeScore = match['score']?['fullTime']?['home'];
    final awayScore = match['score']?['fullTime']?['away'];

    // قراءة الدقيقة الحالية ودقائق الأهداف (إن توفرت)
    final int currentMinute = match['minute'] ?? 31;
    final List<int> goalMinutes = (match['goalMinutes'] as List?)?.map((e) => e as int).toList() ??
        (isLive && ((homeScore ?? 0) + (awayScore ?? 0) > 0) ? [currentMinute] : []);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLive ? Colors.redAccent.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Row(
          children: [
            // الفريق الأول (المضيف)
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTeamLogo(homeCrest),
                ],
              ),
            ),

            // منطقة المنتصف (الدائرة والنتيجة في المباشر، أو وقت المباراة)
            SizedBox(
              width: 105,
              child: isLive
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${homeScore ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        MatchMinuteCircle(
                          minute: currentMinute,
                          goalMinutes: goalMinutes,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${awayScore ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : isFinished
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${homeScore ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '-',
                                style: TextStyle(color: AppColors.muted, fontSize: 16),
                              ),
                            ),
                            Text(
                              '${awayScore ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              match['time'] ?? '03:00',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'مساءً',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
            ),

            // الفريق الثاني (الضيف)
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTeamLogo(awayCrest),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      awayTeam,
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

  Widget _buildTeamLogo(String url) {
    if (url.isEmpty) {
      return const CircleAvatar(
        radius: 13,
        backgroundColor: Colors.transparent,
        child: Icon(Icons.sports_soccer, size: 22, color: AppColors.muted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Image.network(
        url,
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.sports_soccer,
          size: 24,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
