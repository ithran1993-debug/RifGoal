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
  late DateTime selectedDate;
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
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    _matchesFuture = MatchService.getMatches();
  }

  void _refresh() {
    setState(() {
      _matchesFuture = MatchService.getMatches();
    });
  }

  String _formatDayTab(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff == -1) return 'أمس';

    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[date.weekday - 1];
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // قائمة الأيام من أمس حتى 4 أيام قادمة
    final availableDays = List.generate(
      6,
      (index) => today.add(Duration(days: index - 1)),
    );

    return Column(
      children: [
        // 1. شريط اختيار الأيام
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: AppColors.card,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: availableDays.length,
            itemBuilder: (context, index) {
              final day = availableDays[index];
              final isSelected = _isSameDay(day, selectedDate);

              return GestureDetector(
                onTap: () => setState(() => selectedDate = day),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDayTab(day),
                        style: TextStyle(
                          color: isSelected ? AppColors.background : AppColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${day.day}/${day.month}',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.background.withOpacity(0.8)
                              : AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 2. فلتر الدوريات
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: leagues.entries.map((e) {
              final isSelected = selectedLeague == e.key;
              return GestureDetector(
                onTap: () => setState(() => selectedLeague = e.key),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold.withOpacity(0.2) : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isSelected ? AppColors.gold : AppColors.text,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // 3. عرض المباريات لليوم المحدد
        Expanded(
          child: FutureBuilder<List<Match>>(
            future: _matchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }

              if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لا توجد مباريات متاحة حالياً',
                          style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _refresh, child: const Text('تحديث')),
                    ],
                  ),
                );
              }

              var allMatches = snapshot.data!;

              // تصفية حسب اليوم المختار
              var matches = allMatches.where((m) => _isSameDay(m.date, selectedDate)).toList();

              // تصفية حسب الدوري
              if (selectedLeague != 'all') {
                matches = matches.where((m) => m.league == selectedLeague).toList();
              }

              if (matches.isEmpty) {
                return const Center(
                  child: Text('لا توجد مباريات في هذا اليوم',
                      style: TextStyle(color: AppColors.muted)),
                );
              }

              // تجميع مباريات اليوم حسب اسم البطولة
              final Map<String, List<Match>> byLeague = {};
              for (var m in matches) {
                byLeague.putIfAbsent(m.leagueName, () => []).add(m);
              }

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                color: AppColors.gold,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: byLeague.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.border)),
                            ),
                            child: Row(
                              children: [
                                const Text('🏆', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...entry.value.map((match) {
                            return MatchCard(
                              match: match,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MatchDetailsScreen(match: match),
                                  ),
                                );
                              },
                            );
                          }).toList(),
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
