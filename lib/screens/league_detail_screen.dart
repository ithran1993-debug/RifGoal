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

  static const String _apiKey = 'eed3b9bde17f4f1694c0796bf739bbb7';

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
      final headers = {'X-Auth-Token': _apiKey};

      // جلب المباريات
      final matchesUrl = Uri.parse(
          'https://api.football-data.org/v4/competitions/${widget.leagueCode}/matches');
      final matchesRes = await http.get(matchesUrl, headers: headers);

      // جلب جدول الترتيب
      final standingsUrl = Uri.parse(
          'https://api.football-data.org/v4/competitions/${widget.leagueCode}/standings');
      final standingsRes = await http.get(standingsUrl, headers: headers);

      if (matchesRes.statusCode == 200) {
        final matchesData = json.decode(matchesRes.body);
        _matches = matchesData['matches'] ?? [];
      }

      if (standingsRes.statusCode == 200) {
        final standingsData = json.decode(standingsRes.body);
        final tableList = standingsData['standings'] as List? ?? [];
        if (tableList.isNotEmpty) {
          _standings = tableList[0]['table'] ?? [];
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل البيانات، يرجى التحقق من اتصال الإنترنت';
      });
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
          final match = _matches[index];
          final rawHome = match['homeTeam']?['name'] ?? '';
          final rawAway = match['awayTeam']?['name'] ?? '';
          final homeTeam = AppConstants.translateTeam(rawHome);
          final awayTeam = AppConstants.translateTeam(rawAway);
          final homeScore = match['score']?['fullTime']?['home'];
          final awayScore = match['score']?['fullTime']?['away'];
          final status = match['status'] ?? '';

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
                    status == 'FINISHED'
                        ? '$homeScore -$awayScore'
                        : (status == 'IN_PLAY' || status == 'LIVE' ? 'مباشر' : 'لم تبدأ'),
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
