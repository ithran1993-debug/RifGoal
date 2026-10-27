import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  String selectedLeague = 'PL';
  late Future<List<Map<String, dynamic>>> _standingsFuture;

  final Map<String, String> leagues = {
    'PL': 'الدوري الإنجليزي',
    'PD': 'الدوري الإسباني',
    'SA': 'الدوري الإيطالي',
    'BL1': 'الدوري الألماني',
    'FL1': 'الدوري الفرنسي',
    'CL': 'أبطال أوروبا',
  };

  static const String _apiKey = 'eed3b9bde17f4f1694c0796bf739bbb7';
  static const String _baseUrl = 'https://api.football-data.org/v4';

  @override
  void initState() {
    super.initState();
    _standingsFuture = _fetchStandings(selectedLeague);
  }

  Future<List<Map<String, dynamic>>> _fetchStandings(String leagueCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/competitions/$leagueCode/standings'),
        headers: {'X-Auth-Token': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List tables = data['standings'] ?? [];

        // عادة يكون الجدول الأول هو الترتيب العام
        if (tables.isNotEmpty) {
          final table = tables[0]['table'] as List? ?? [];
          return table.map((row) {
            return {
              'pos': row['position'],
              'team': row['team']?['shortName'] ?? row['team']?['name'] ?? 'فريق',
              'played': row['playedGames'],
              'won': row['won'],
              'draw': row['draw'],
              'lost': row['lost'],
              'pts': row['points'],
              'crest': row['team']?['crest'] ?? '',
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('خطأ في جلب الترتيب: $e');
      return [];
    }
  }

  void _changeLeague(String code) {
    setState(() {
      selectedLeague = code;
      _standingsFuture = _fetchStandings(code);
    });
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
                onTap: () => _changeLeague(e.key),
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _standingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold));
              }

              if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                return const Center(
                  child: Text('لا توجد بيانات حالياً', style: TextStyle(color: AppColors.muted)),
                );
              }

              final table = snapshot.data!;

              return Container(
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
                          SizedBox(width: 28, child: Text('ل', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          SizedBox(width: 28, child: Text('ف', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          SizedBox(width: 28, child: Text('ت', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          SizedBox(width: 28, child: Text('خ', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          SizedBox(width: 35, child: Text('نقاط', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),

                    // الصفوف
                    Expanded(
                      child: ListView.builder(
                        itemCount: table.length,
                        itemBuilder: (context, index) {
                          final row = table[index];
                          final isTop = (row['pos'] as int) <= 3;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                              color: isTop ? AppColors.gold.withOpacity(0.06) : null,
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
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 28, child: Text('${row['played']}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 13))),
                                SizedBox(width: 28, child: Text('${row['won']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                                SizedBox(width: 28, child: Text('${row['draw']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                                SizedBox(width: 28, child: Text('${row['lost']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                                SizedBox(
                                  width: 35,
                                  child: Text(
                                    '${row['pts']}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold, fontSize: 13)  ,
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
              );
            },
          ),
        ),
      ],
    );
  }
}
