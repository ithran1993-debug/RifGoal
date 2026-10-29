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

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(date.year, date.month, date.day);
    final diff = matchDay.difference(today).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غدًا';
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
    return '${days[date.weekday - 1]}  \( {date.day}/ \){date.month}';
  }

  // مفتاح للترتيب الزمني
  String _dayKey(DateTime date) {
    return '\( {date.year}- \){date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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

              if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لا توجد مباريات حالياً', style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _refresh, child: const Text('تحديث')),
                    ],
                  ),
                );
              }

              var matches = snapshot.data!;
              if (selectedLeague != 'all') {
                matches = matches.where((m) => m.league == selectedLeague).toList();
              }

              if (matches.isEmpty) {
                return const Center(
                  child: Text('لا توجد مباريات لهذا الدوري', style: TextStyle(color: AppColors.muted)),
                );
              }

              // تجميع حسب اليوم مع ترتيب زمني
              final Map<String, List<Match>> grouped = {};
              final Map<String, String> keyToLabel = {};

              for (var match in matches) {
                final date = match.date ?? DateTime.now();
                final key = _dayKey(date);
                final label = _getDayLabel(date);
                keyToLabel[key] = label;
                grouped.putIfAbsent(key, () => []).add(match);
              }

              // ترتيب المفاتيح زمنياً
              final sortedKeys = grouped.keys.toList()..sort();

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                color: AppColors.gold,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: sortedKeys.map((key) {
                    final dayMatches = grouped[key]!;
                    final dayLabel = keyToLabel[key]!;

                    // تجميع حسب الدوري داخل اليوم
                    final Map<String, List<Match>> byLeague = {};
                    for (var m in dayMatches) {
                      byLeague.putIfAbsent(m.leagueName, () => []).add(m);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عنوان اليوم
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                          ),
                          child: Text(
                            dayLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ),

                        // الدوريات
                        ...byLeague.entries.map((entry) {
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppColors.border)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('🏆', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          font
