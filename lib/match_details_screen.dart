import 'package:flutter/material.dart';
import 'match_model.dart';

class MatchDetailsScreen extends StatelessWidget {
  final FootballMatch match;

  const MatchDetailsScreen({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardColor = isDark
        ? const Color(0xFF161B22)
        : Colors.white;

    final Color mutedColor = theme.colorScheme.onSurfaceVariant;

    final String status = match.isLive
        ? 'مباشر'
        : match.isFinished
            ? 'انتهت المباراة'
            : match.statusLong.isNotEmpty
                ? match.statusLong
                : 'لم تبدأ';

    final Color statusColor = match.isLive
        ? Colors.red
        : match.isFinished
            ? Colors.green
            : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل المباراة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // معلومات البطولة
          Center(
            child: Column(
              children: [
                Text(
                  match.leagueName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (match.leagueCountry.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    match.leagueCountry,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 22),

          // بطاقة النتيجة
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 25,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TeamColumn(
                        name: match.homeTeam,
                        logo: match.homeLogo,
                      ),
                    ),

                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${match.homeScore ?? '-'} : ${match.awayScore ?? '-'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              match.isLive &&
                                      match.elapsed != null
                                  ? '$status ${match.elapsed}'
                                  : status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _TeamColumn(
                        name: match.awayTeam,
                        logo: match.awayLogo,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Divider(
                  color: theme.dividerColor.withOpacity(0.3),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 17,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        match.date,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // عنوان المعلومات
          const Text(
            'معلومات المباراة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // بطاقة المعلومات
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'التاريخ',
                  value: match.date,
                ),

                _InfoRow(
                  icon: Icons.stadium_outlined,
                  title: 'الملعب',
                  value: _valueOrDefault(match.stadium),
                ),

                _InfoRow(
                  icon: Icons.sports,
                  title: 'الحكم',
                  value: _valueOrDefault(match.referee),
                ),

                _InfoRow(
                  icon: Icons.flag_outlined,
                  title: 'البلد',
                  value: _valueOrDefault(match.leagueCountry),
                ),

                _InfoRow(
                  icon: Icons.emoji_events_outlined,
                  title: 'البطولة',
                  value: _valueOrDefault(match.leagueName),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _valueOrDefault(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'غير متوفر';
    }
    return value;
  }
}

// عرض الفريق وشعاره
class _TeamColumn extends StatelessWidget {
  final String name;
  final String logo;

  const _TeamColumn({
    required this.name,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: logo.isEmpty
              ? const Icon(
                  Icons.shield_outlined,
                  size: 55,
                )
              : Image.network(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.shield_outlined,
                      size: 55,
                    );
                  },
                ),
        ),

        const SizedBox(height: 12),

        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// سطر معلومات المباراة
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor =
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showDivider)
          Divider(
            height: 1,
            color: Theme.of(context)
                .dividerColor
                .withOpacity(0.2),
          ),
      ],
    );
  }
}
