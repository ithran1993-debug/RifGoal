import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/match_card.dart';
import 'match_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedLeague = 'all';

  final Map<String, String> leagues = {
    'all': 'الكل',
    'ucl': 'أبطال أوروبا',
    'epl': 'الإنجليزي',
    'botola': 'البطولة',
  };

  @override
  Widget build(BuildContext context) {
    final matches = MatchService.getByLeague(selectedLeague);
    final grouped = <String, List<Match>>{};
    for (var m in matches) {
      grouped.putIfAbsent(m.leagueName, () => []).add(m);
    }

    return Column(
      children: [
        // فلتر الدوريات
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: leagues.entries.map((e) {
              final isSelected = selectedLeague == e.key;
              return GestureDetector(
                onTap: () => setState(() => selectedLeague = e.key),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.gold : AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isSelected ? AppColors.background : AppColors.text,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // قائمة المباريات
        Expanded(
          child: matches.isEmpty
              ? const Center(child: Text('لا توجد مباريات', style: TextStyle(color: AppColors.muted)))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: grouped.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          // عنوان الدوري
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.border)),
                            ),
                            child: Row(
                              children: [
                                const Text('🏆', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              ],
                            ),
                          ),
                          // المباريات
                          ...entry.value.map((match) => MatchCard(
                                match: match,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MatchDetailsScreen(match: match),
                                    ),
                                  );
                                },
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
