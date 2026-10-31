import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'league_detail_screen.dart';

class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  final List leagues = const [
    {'name': 'دوري أبطال أوروبا', 'code': 'CL', 'country': 'أوروبا', 'emoji': '🏆'},
    {'name': 'الدوري الإنجليزي', 'code': 'PL', 'country': 'إنجلترا', 'emoji': '🏴󠁧󠁢󠁥󠁮󠁧󠁿'},
    {'name': 'الدوري الإسباني', 'code': 'PD', 'country': 'إسبانيا', 'emoji': '🇪🇸'},
    {'name': 'الدوري الإيطالي', 'code': 'SA', 'country': 'إيطاليا', 'emoji': '🇮🇹'},
    {'name': 'الدوري الألماني', 'code': 'BL1', 'country': 'ألمانيا', 'emoji': '🇩🇪'},
    {'name': 'الدوري الفرنسي', 'code': 'FL1', 'country': 'فرنسا', 'emoji': '🇫🇷'},
    {'name': 'الدوري الأوروبي', 'code': 'EL', 'country': 'أوروبا', 'emoji': '🌍'},
    {'name': 'البطولة المغربية', 'code': 'BOTOLA', 'country': 'المغرب', 'emoji': '🇲🇦'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: leagues.length,
      itemBuilder: (context, index) {
        final league = leagues[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  league['emoji'] ?? '',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            title: Text(
              league['name'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.text,
              ),
            ),
            subtitle: Text(
              league['country'] ?? '',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.muted,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeagueDetailScreen(
                    leagueName: league['name'] ?? '',
                    leagueCode: league['code'] ?? '',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
