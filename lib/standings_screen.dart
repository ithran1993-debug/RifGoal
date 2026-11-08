import 'package:flutter/material.dart';

import 'api_config.dart';
import 'standing_model.dart';
import 'standings_service.dart';
import 'football_translations.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  final StandingsService _service = StandingsService();

  String selectedLeague = 'الدوري الإنجليزي';

  final List<String> leagues = [
    'الدوري الإنجليزي',
    'الدوري الإسباني',
    'الدوري الإيطالي',
    'الدوري الألماني',
    'الدوري الفرنسي',
  ];

  final Map<String, int> leagueIds = {
    'الدوري الإنجليزي': 39,
    'الدوري الإسباني': 140,
    'الدوري الإيطالي': 135,
    'الدوري الألماني': 78,
    'الدوري الفرنسي': 61,
  };

  List<Standing> standings = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  int _getSeason() {
    final now = DateTime.now();
    return now.month >= 7 ? now.year : now.year - 1;
  }

  Future<void> _loadStandings() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final leagueId = leagueIds[selectedLeague];

      if (leagueId == null) {
        throw Exception('البطولة غير معروفة.');
      }

      final endpoint = Uri.parse(
        '${ApiConfig.baseUrl}/api/standings',
      ).replace(
        queryParameters: {
          'league': leagueId.toString(),
          'season': _getSeason().toString(),
        },
      );

      final result = await _service.fetchStandings(
        endpoint: endpoint,
      );

      if (!mounted) return;

      setState(() {
        standings = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Theme.of(context)
                    .dividerColor
                    .withOpacity(0.25),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLeague,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primary,
                ),
                items: leagues.map((league) {
                  return DropdownMenuItem<String>(
                    value: league,
                    child: Text(
                      league,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null && value != selectedLeague) {
                    setState(() {
                      selectedLeague = value;
                    });
                    _loadStandings();
                  }
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.leaderboard_rounded,
                color: primary,
                size: 21,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'جدول الترتيب',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: isLoading ? null : _loadStandings,
                tooltip: 'تحديث',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),

        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return _message(
        Icons.wifi_off_rounded,
        'تعذر تحميل الترتيب',
        errorMessage!,
        true,
      );
    }

    if (standings.isEmpty) {
      return _message(
        Icons.leaderboard_outlined,
        'لا يوجد ترتيب متاح',
        'لم تصل بيانات الترتيب لهذه البطولة حالياً.',
        false,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStandings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 25),
        children: [
          _buildTable(),
          const SizedBox(height: 18),
          _buildLegend(),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'اسحب للأسفل لتحديث الترتيب',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 610,
            child: Column(
              children: [
                _buildHeader(),
                ...standings.map(_buildStandingRow),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 48,
      color: primary,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Row(
        children: [
          _HeaderCell('#', width: 35),
          _HeaderCell('الفريق', width: 175, alignStart: true),
          _HeaderCell('لعب', width: 45),
          _HeaderCell('فاز', width: 45),
          _HeaderCell('تعادل', width: 45),
          _HeaderCell('خسر', width: 45),
          _HeaderCell('له', width: 45),
          _HeaderCell('عليه', width: 45),
          _HeaderCell('النقاط', width: 65),
        ],
      ),
    );
  }

  Widget _buildStandingRow(Standing item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color? positionColor = item.position <= 4
        ? Colors.green.withOpacity(0.10)
        : null;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: positionColor ??
            (isDark
                ? const Color(0xFF161B22)
                : Colors.white),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Center(
              child: Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.position <= 4
                      ? Colors.green.withOpacity(0.15)
                      : theme.dividerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.position}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: item.position <= 4
                        ? Colors.green
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(
            width: 175,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: item.teamLogo.isEmpty
                      ? const Icon(Icons.shield_outlined)
                      : Image.network(
                          item.teamLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.shield_outlined,
                            );
                          },
                        ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    FootballTranslations.team(item.teamName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _DataCell('${item.played}', width: 45),
          _DataCell('${item.won}', width: 45),
          _DataCell('${item.drawn}', width: 45),
          _DataCell('${item.lost}', width: 45),
          _DataCell('${item.goalsFor}', width: 45),
          _DataCell('${item.goalsAgainst}', width: 45),

          SizedBox(
            width: 65,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${item.points}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: [
        _LegendItem(
          color: Colors.green,
          text: 'المراكز الأربعة الأولى',
        ),
        _LegendItem(
          color: Colors.grey,
          text: 'بقية المراكز',
        ),
      ],
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String subtitle,
    bool showRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 55,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight
