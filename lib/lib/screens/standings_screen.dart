import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  String selectedLeague = 'botola';

  final Map<String, String> leagues = {
    'botola': 'البطولة المغربية',
    'epl': 'الدوري الإنجليزي',
    'ucl': 'أبطال أوروبا',
  };

  // بيانات وهمية للترتيب
  final Map<String, List<Map<String, dynamic>>> standings = {
    'botola': [
      {'pos': 1, 'team': 'الوداد', 'played': 7, 'won': 5, 'draw': 1, 'lost': 1, 'pts': 16},
      {'pos': 2, 'team': 'الرجاء', 'played': 7, 'won': 4, 'draw': 2, 'lost': 1, 'pts': 14},
      {'pos': 3, 'team': 'الجيش الملكي', 'played': 7, 'won': 4, 'draw': 1, 'lost': 2, 'pts': 13},
      {'pos': 4, 'team': 'الفتح', 'played': 7, 'won': 3, 'draw': 3, 'lost': 1, 'pts': 12},
      {'pos': 5, 'team': 'حسنية أكادير', 'played': 7, 'won': 3, 'draw': 2, 'lost': 2, 'pts': 11},
      {'pos': 6, 'team': 'المغرب الفاسي', 'played': 7, 'won': 2, 'draw': 3, 'lost': 2, 'pts': 9},
    ],
    'epl': [
      {'pos': 1, 'team': 'مانشستر سيتي', 'played': 9, 'won': 7, 'draw': 1, 'lost': 1, 'pts': 22},
      {'pos': 2, 'team': 'آرسنال', 'played': 9, 'won': 6, 'draw': 2, 'lost': 1, 'pts': 20},
      {'pos': 3, 'team': 'ليفربول', 'played': 9, 'won': 6, 'draw': 1, 'lost': 2, 'pts': 19},
      {'pos': 4, 'team': 'توتنهام', 'played': 9, 'won': 5, 'draw': 2, 'lost': 2, 'pts': 17},
      {'pos': 5, 'team': 'تشيلسي', 'played': 9, 'won': 4, 'draw': 3, 'lost': 2, 'pts': 15},
    ],
    'ucl': [
      {'pos': 1, 'team': 'برشلونة', 'played': 3, 'won': 3, 'draw': 0, 'lost': 0, 'pts': 9},
      {'pos': 2, 'team': 'بايرن ميونخ', 'played': 3, 'won': 2, 'draw': 1, 'lost': 0, 'pts': 7},
      {'pos': 3, 'team': 'مانشستر سيتي', 'played': 3, 'won': 2, 'draw': 0, 'lost': 1, 'pts': 6},
      {'pos': 4, 'team': 'ريال مدريد', 'played': 3, 'won': 1, 'draw': 2, 'lost': 0, 'pts': 5},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final table = standings[selectedLeague] ?? [];

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

        // جدول الترتيب
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // رأس الجدول
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 30, child: Text('#', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('الفريق', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold))),
                      SizedBox(width: 30, child: Text('ل', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      SizedBox(width: 30, child: Text('ف', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      SizedBox(width: 30, child: Text('ت', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      SizedBox(width: 30, child: Text('خ', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      SizedBox(width: 35, child: Text('نقاط', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    ],
                  ),
                ),

                // صفوف الترتيب
                Expanded(
                  child: ListView.builder(
                    itemCount: table.length,
                    itemBuilder: (context, index) {
                      final row = table[index];
                      final isTop = row['pos'] <= 3;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                          color: isTop ? AppColors.gold.withOpacity(0.05) : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${row['pos']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isTop ? AppColors.gold : AppColors.text,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                row['team'],
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            SizedBox(width: 30, child: Text('${row['played']}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted))),
                            SizedBox(width: 30, child: Text('${row['won']}', textAlign: TextAlign.center)),
                            SizedBox(width: 30, child: Text('${row['draw']}', textAlign: TextAlign.center)),
                            SizedBox(width: 30, child: Text('${row['lost']}', textAlign: TextAlign.center)),
                            SizedBox(
                              width: 35,
                              child: Text(
                                '${row['pts']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
