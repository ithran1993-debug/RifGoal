import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class LeagueDetailScreen extends StatefulWidget {
  final String leagueName;
  final String leagueCode;

  const LeagueDetailScreen({
    super.key,
    required this.leagueName,
    required this.leagueCode,
  });

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _matches = [];
  List<dynamic> _standings = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const String _apiKey = '60380bdc41e945a2c17619bdcc6944bf';
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  String _resolveLeagueId(String code) {
    final clean = code.trim().toUpperCase();
    switch (clean) {
      case 'PL':
      case 'PREMIER':
        return '39';
      case 'PD':
      case 'LALIGA':
        return '140';
      case 'SA':
      case 'SERIE_A':
        return '135';
      case 'BL1':
      case 'BUNDESLIGA':
        return '78';
      case 'FL1':
      case 'LIGUE1':
        return '61';
      case 'CL':
      case 'CHAMPIONS':
        return '2';
      case 'EL':
      case 'EUROPA':
        return '3';
      case 'BOTOLA':
        return '200';
      default:
        return int.tryParse(clean) != null ? clean : '39';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLeagueData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeagueData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = {'x-apisports-key': _apiKey};
      final leagueId = _resolveLeagueId(widget.leagueCode);
      final currentSeason = DateTime.now().year;

      final matchesUrl = Uri.parse('$_baseUrl/fixtures?league=$leagueId&season=$currentSeason&next=15');
      final matchesRes = await http.get(matchesUrl, headers: headers).timeout(const Duration(seconds: 12));

      final standingsUrl = Uri.parse('$_baseUrl/standings?league=$leagueId&season=$currentSeason');
      final standingsRes = await http.get(standingsUrl, headers: headers).timeout(const Duration(seconds: 12));

      if (matchesRes.statusCode == 200) {
        final matchesData = json.decode(matchesRes.body);
        _matches = matchesData['response'] ?? [];
      }

      if (standingsRes.statusCode == 200) {
        final standingsData = json.decode(standingsRes.body);
        final resList = standingsData['response'] as List? ?? [];
        if (resList.isNotEmpty) {
          final leagueObj = resList[0]['league'];
          if (leagueObj != null && leagueObj['standings'] is List && (leagueObj['standings'] as List).isNotEmpty) {
            _standings = leagueObj['standings'][0] ?? [];
          }
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر تحميل البيانات، يرجى التحقق من اتصال الإنترنت';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text(
          widget.leagueName,
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.muted,
          tabs: const [
            Tab(icon: Icon(Icons.sports_soccer), text: 'المباريات'),
            Tab(icon: Icon(Icons.format_list_numbered), text: 'الترتيب'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                          onPressed: _fetchLeagueData,
                          child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.black)),
                        )
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMatchesTab(),
                    _buildStandingsTab(),
                  ],
                ),
    );
  }

  Widget _buildMatchesTab() {
    if (_matches.isEmpty) {
      return const Center(
        child: Text('لا توجد مباريات متاحة حالياً', style: TextStyle(color: AppColors.muted)),
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _fetchLeagueData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final item = _matches[index];
          final teams = item['teams'] ?? {};
          final goals = item['goals'] ?? {};
          final statusInfo = item['fixture']?['status'] ?? {};
          final short = (statusInfo['short'] ?? '').toString();

          final homeRaw = (teams['home']?['name'] ?? 'المضيف').toString();
          final awayRaw = (teams['away']?['name'] ?? 'الضيف').toString();
          final homeTeam = AppConstants.translateTeam(homeRaw);
          final awayTeam = AppConstants.translateTeam(awayRaw);

          final homeScore = goals['home'];
          final awayScore = goals['away'];

          String resultText;
          if (['FT', 'AET', 'PEN'].contains(short)) {
            resultText = '${homeScore ?? 0} - ${awayScore ?? 0}';
          } else if (['1H', '2H', 'ET', 'LIVE'].contains(short)) {
            resultText = '${statusInfo['elapsed'] ?? ''}\'';
          } else {
            final dtStr = item['fixture']?['date'];
            if (dtStr != null) {
              final dt = DateTime.tryParse(dtStr.toString())?.toLocal();
              resultText = dt != null
                  ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                  : 'قادمة';
            } else {
              resultText = 'قادمة';
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    homeTeam,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    resultText,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    awayTeam,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStandingsTab() {
    if (_standings.isEmpty) {
      return const Center(
        child: Text('جدول الترتيب غير متاح حالياً', style: TextStyle(color: AppColors.muted)),
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _fetchLeagueData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DataTable(
            horizontalMargin: 8,
            columnSpacing: 14,
            columns: const [
              DataColumn(label: Text('#', style: TextStyle(color: AppColors.gold))),
              DataColumn(label: Text('الفريق', style: TextStyle(color: AppColors.gold))),
              DataColumn(label: Text('لعب', style: TextStyle(color: AppColors.gold))),
              DataColumn(label: Text('فارق', style: TextStyle(color: AppColors.gold))),
              DataColumn(label: Text('نقاط', style: TextStyle(color: AppColors.gold))),
            ],
            rows: _standings.map((row) {
              final teamNameRaw = (row['team']?['name'] ?? '').toString();
              final teamName = AppConstants.translateTeam(teamNameRaw);
              final allStats = row['all'] ?? {};

              return DataRow(cells: [
                DataCell(Text('${row['rank'] ?? ''}', style: const TextStyle(color: Colors.white70))),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      teamName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(Text('${allStats['played'] ?? ''}', style: const TextStyle(color: Colors.white70))),
                DataCell(Text('${row['goalsDiff'] ?? ''}', style: const TextStyle(color: Colors.white70))),
                DataCell(Text('${row['points'] ?? ''}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
