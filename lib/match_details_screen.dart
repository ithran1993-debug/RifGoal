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
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المباراة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(
              match.leagueName,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TeamColumn(
                  name: match.homeTeam,
                  logo: match.homeLogo,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${match.homeScore ?? '-'} : ${match.awayScore ?? '-'}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    match.isLive
                        ? 'مباشر ${match.elapsed ?? ''}'
                        : match.isFinished
                            ? 'انتهت المباراة'
                            : match.statusLong.isNotEmpty
                                ? match.statusLong
                                : 'موعد المباراة',
                    style: TextStyle(
                      color: match.isLive
                          ? Colors.red
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: _TeamColumn(
                  name: match.awayTeam,
                  logo: match.awayLogo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'معلومات المباراة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'التاريخ',
            value: match.date,
          ),
          _InfoRow(
            icon: Icons.stadium_outlined,
            title: 'الملعب',
            value: match.stadium ?? 'غير متوفر',
          ),
          _InfoRow(
            icon: Icons.sports,
            title: 'الحكم',
            value: match.referee ?? 'غير متوفر',
          ),
          _InfoRow(
            icon: Icons.flag_outlined,
            title: 'البلد',
            value: match.leagueCountry,
          ),
        ],
      ),
    );
  }
}

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
          height: 65,
          width: 65,
          child: logo.isEmpty
              ? const Icon(Icons.shield_outlined, size: 48)
              : Image.network(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.shield_outlined,
                      size: 48,
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: SizedBox(
        width: 180,
        child: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
