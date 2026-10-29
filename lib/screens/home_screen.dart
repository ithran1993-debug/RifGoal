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
  late Future<List<Match>> _matchesFuture;

  final Map<String, String> leagues = {
    'all': 'الكل',
    'cl': 'أبطال أوروبا',
    'pl': 'الإنجليزي',
    'pd': 'الإسباني',
    'sa': 'الإيطالي',
    'bl1': 'الألماني',
  };

  @override
  void initState() {
    super.initState();
    _matchesFuture = MatchService.getMatches();
  }

  void _refresh() {
    setState(() {
      _matchesFuture = MatchService.getMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.border,
                    ),
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
        Expanded(
          child: FutureBuilder<List<Match>>(
            future: _matchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('خطأ: ${snapshot.error}', style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                );
              }

              final allMatches = snapshot.data ?? [];
              final matches = selectedLeague == 'all'
                  ? allMatches
                  : allMatches.where((m) => m.league == selectedLeague).toList();

              if (matches.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لا توجد مباريات حالياً', style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 8),
                      const Text('قد لا توجد مباريات اليوم في الدوريات المجانية', 
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _refresh, child: const Text('تحديث')),
                    ],
                  ),
                );
              }

              final grouped = <String, List<Match>>{};
              for (var m in matches) {
                grouped.putIfAbsent(m.leagueName, () => []).add(m);
              }

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                color: AppColors.gold,
                child: ListView(
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
              );
            },
          ),
        ),
      ],
    );
  }
}
