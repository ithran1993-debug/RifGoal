import 'package:flutter/material.dart';

class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  static const List<Map<String, dynamic>> leagues = [
    {
      'name': 'دوري أبطال أوروبا',
      'country': 'أوروبا',
      'icon': Icons.emoji_events,
    },
    {
      'name': 'الدوري الإنجليزي',
      'country': 'إنجلترا',
      'icon': Icons.sports_soccer,
    },
    {
      'name': 'الدوري الإسباني',
      'country': 'إسبانيا',
      'icon': Icons.sports_soccer,
    },
    {
      'name': 'الدوري الإيطالي',
      'country': 'إيطاليا',
      'icon': Icons.sports_soccer,
    },
    {
      'name': 'الدوري الألماني',
      'country': 'ألمانيا',
      'icon': Icons.sports_soccer,
    },
    {
      'name': 'الدوري الفرنسي',
      'country': 'فرنسا',
      'icon': Icons.sports_soccer,
    },
    {
      'name': 'البطولة الاحترافية',
      'country': 'المغرب',
      'icon': Icons.sports_soccer,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: leagues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final league = leagues[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primary.withOpacity(0.12),
                child: Icon(
                  league['icon'] as IconData,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      league['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      league['country'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: primary,
              ),
            ],
          ),
        );
      },
    );
  }
}
