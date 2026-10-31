import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamName;

  const TeamDetailScreen({super.key, required this.teamName});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _teamMatches = [];

  static const String _apiKey = '60380bdc41e945a2c17619bdcc6944bf';
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  // معرّفات الأندية في API-Sports
  final Map<String, int> teamIds = const {
    'ريال مدريد': 541,
    'برشلونة': 529,
    'أتلتيكو مدريد': 530,
    'إشبيلية': 536,
    'مانشستر سيتي': 50,
    'ليفربول': 40,
    'أرسنال': 42,
    'آرسنال': 42,
    'تشيلسي': 49,
    'مانشستر يونايتد': 33,
    'توتنهام': 47,
    'بايرن ميونخ': 157,
    'بوروسيا دورتموند': 165,
    'دورتموند': 165,
    'باريس سان جيرمان': 85,
    'يوفنتوس': 496,
    'إنتر ميلان': 505,
    'إنتر': 505,
    'ميلان': 489,
    'نابولي': 492,
    'الوداد': 968,
    'الرجاء': 967,
    'الجيش الملكي': 969,
    'الفتح': 970,
    'حسنية أكادير': 971,
    'المغرب الفاسي': 973,
  };

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    final teamId = teamIds[widget.teamName];
    if (teamId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/fixtures?team=$teamId&last=10'),
        headers: {'x-apisports-key': _apiKey},
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _teamMatches = data['response'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeUrl = AppConstants.teamBadges[widget.teamName];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text(
          widget.teamName,
          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        badgeUrl != null
                            ? Image.network(
                                badgeUrl,
                                width: 70,
                                height: 70,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.sports_soccer,
                                  size: 60,
                                  color: AppColors.gold,
                                ),
                              )
                            : const Icon(Icons.sports_soccer, size: 60, color: AppColors.gold),
                        const SizedBox(height: 12),
                        Text(
                          widget.teamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('نادي مفضل', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'مباريات ${widget.teamName}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _teamMatches.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'لا توجد مباريات مسجلة حالياً لهذا النادي',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _teamMatches.length,
                          itemBuilder: (context, index) {
                            final item = _teamMatches[index];
                            final teams = item['teams'] ?? {};
                            final goals = item['goals'] ?? {};

                            final hRaw = (teams['home']?['name'] ?? 'المضيف').toString();
                            final aRaw = (teams['away']?['name'] ?? 'الضيف').toString();
                            final hName = AppConstants.translateTeam(hRaw);
                            final aName = AppConstants.translateTeam(aRaw);

                            final hScore = goals['home'] ?? '-';
                            final aScore = goals['away'] ?? '-';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      hName,
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$hScore : $aScore',
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      aName,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
