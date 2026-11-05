import 'package:flutter/material.dart';

import 'api_config.dart';
import 'standing_model.dart';
import 'standings_service.dart';

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
    'البطولة المغربية',
  ];

  final Map<String, int> leagueIds = {
    'الدوري الإنجليزي': 39,
    'الدوري الإسباني': 140,
    'الدوري الإيطالي': 135,
    'الدوري الألماني': 78,
    'الدوري الفرنسي': 61,
    'البطولة المغربية': 200,
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
    return Column(
      children: [
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonFormField<String>(
            value: selectedLeague,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'اختر البطولة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: leagues.map((league) {
              return DropdownMenuItem<String>(
                value: league,
                child: Text(league),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedLeague = value;
                });
                _loadStandings();
              }
            },
          ),
        ),

        const SizedBox(height: 16),

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
        Icons.wifi_off,
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
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
        children: [
          _buildHeader(),

          const SizedBox(height: 8),

          ...standings.map(_buildStandingRow),

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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              'الفريق',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          _HeaderCell('لعب'),
          _HeaderCell('ف'),
          _HeaderCell('ت'),
          _HeaderCell('خ'),
          _HeaderCell('له'),
          _HeaderCell('عليه'),
          _HeaderCell('النقاط'),
        ],
      ),
    );
  }

  Widget _buildStandingRow(Standing item) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final background = isDark
        ? const Color(0xFF161B22)
        : Colors.white;

    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${item.position}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: item.position <= 4
                    ? Theme.of(context).colorScheme.primary
                    : textColor,
              ),
            ),
          ),

          Expanded(
            flex: 5,
            child: Row(
              children: [
                SizedBox(
                  width: 25,
                  height: 25,
                  child: item.teamLogo.isEmpty
                      ? const Icon(
                          Icons.shield_outlined,
                          size: 22,
                        )
                      : Image.network(
                          item.teamLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.shield_outlined,
                              size: 22,
                            );
                          },
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _DataCell('${item.played}'),
          _DataCell('${item.won}'),
          _DataCell('${item.drawn}'),
          _DataCell('${item.lost}'),
          _DataCell('${item.goalsFor}'),
          _DataCell('${item.goalsAgainst}'),

          SizedBox(
            width: 35,
            child: Text(
              '${item.points}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            if (showRetry) ...[
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _loadStandings,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 27,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;

  const _DataCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 27,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}
