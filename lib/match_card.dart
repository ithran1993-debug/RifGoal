import 'package:flutter/material.dart';

class MatchCard extends StatelessWidget {
  final String competition;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final String time;
  final String homeScore;
  final String awayScore;
  final bool isLive;
  final String status;

  const MatchCard({
    super.key,
    required this.competition,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.time,
    required this.homeScore,
    required this.awayScore,
    this.isLive = false,
    this.status = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF161B22)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF30363D)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  competition,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'مباشر',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TeamInfo(
                  name: homeTeam,
                  logo: homeLogo,
                ),
              ),
              Column(
                children: [
                  Text(
                    '$homeScore - $awayScore',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status.isNotEmpty ? status : time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isLive
                          ? const Color(0xFFE53935)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: _TeamInfo(
                  name: awayTeam,
                  logo: awayLogo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark
                ? const Color(0xFF30363D)
                : const Color(0xFFE5E7EB),
            height: 1,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Text(
                'تفاصيل المباراة',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamInfo extends StatelessWidget {
  final String name;
  final String logo;

  const _TeamInfo({
    required this.name,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: logo.isEmpty
              ? const Icon(Icons.shield_outlined, size: 36)
              : Image.network(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shield_outlined,
                      size: 36,
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
