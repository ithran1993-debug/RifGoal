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

  static const String _apiKey = 'eed3b9bde17f4f1694c0796bf739bbb7';

  final Map<String, int> teamIds = const {
    'ريال مدريد': 86,
    'برشلونة': 81,
    'مانشستر سيتي': 65,
    'ليفربول': 64,
    'أرسنال': 57,
    'باريس سان جيرمان': 524,
    'بايرن ميونخ': 5,
    'تشيلسي': 61,
    'مانشستر يونايتد': 66,
    'يوفنتوس': 109,
    'إنتر ميلان': 108,
    'ميلان': 98,
    'أتلتيكو مدريد': 78,
    'بوروسيا دورتموند': 4,
  };

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    final teamId = teamIds[widget.teamName];
    if (teamId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('https://api.football-data.org/v4/teams/$teamId/matches?limit=10'),
        headers: {'X-Auth-Token': _apiKey},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _teamMatches = data['matches'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
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
        title: Text(widget.teamName, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
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
                                errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 60, color: AppColors.gold),
                              )
                            : const Icon(Icons.sports_soccer, size: 60, color: AppColors.gold),
                        const SizedBox(height: 12),
                        Text(widget.teamName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('نادي مفضل', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('مباريات ${widget.teamName}', style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  _teamMatches.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Text('لا توجد مباريات مسجلة حالياً لهذا النادي', style: TextStyle(color: AppColors.muted))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _teamMatches.length,
                          itemBuilder: (context, index) {
                            final m = _teamMatches[index];
                            final hName = AppConstants.translateTeam(m['homeTeam']?['name']);
                            final aName = AppConstants.translateTeam(m['awayTeam']?['name']);
                            final hScore = m['score']?['fullTime']?['home'] ?? '-';
                            final aScore = m['score']?['fullTime']?['away'] ?? '-';

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
                                  Expanded(child: Text(hName, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 13))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                                    child: Text('$hScore : $aScore', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(child: Text(aName, textAlign: TextAlign.left, style: const TextStyle(color: Colors.white, fontSize: 13))),
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
