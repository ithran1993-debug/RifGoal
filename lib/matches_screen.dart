import 'dart:async';
import 'package:flutter/material.dart';

import 'date_selector.dart';
import 'competition_selector.dart';
import 'match_service.dart';
import 'match_model.dart';
import 'api_config.dart';
import 'match_details_screen.dart';
import 'football_translations.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final MatchService _matchService = MatchService();

  DateTime selectedDate = DateTime.now();
  String selectedCompetition = 'ALL';

  List<FootballMatch> matches = [];

  bool isLoading = true;
  String? errorMessage;

  Timer? _refreshTimer;
  int _requestId = 0;

  static const Map<String, int> competitionIds = {
    'CL': 2,
    'PL': 39,
    'PD': 140,
    'SA': 135,
    'BL1': 78,
    'FL1': 61,
  };

  static const Map<int, int> leaguePriority = {
    2: 1,
    39: 2,
    140: 3,
    135: 4,
    78: 5,
    61: 6,
  };

  @override
  void initState() {
    super.initState();

    _loadMatches();

    // تحديث البيانات تلقائياً كل 60 ثانية.
    // Cloudflare يحتفظ بالنتائج لمدة 5 دقائق.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (timer) {
        if (!mounted || isLoading) return;

        _loadMatches(showLoading: false);
      },
    );
  }

  int _getLeaguePriority(FootballMatch match) {
    return leaguePriority[match.leagueId] ?? 100;
  }

  List<FootballMatch> _sortMatches(List<FootballMatch> list) {
    final sorted = List<FootballMatch>.from(list);

    sorted.sort((a, b) {
      final priorityComparison =
          _getLeaguePriority(a).compareTo(_getLeaguePriority(b));

      if (priorityComparison != 0) {
        return priorityComparison;
      }

      return a.date.compareTo(b.date);
    });

    return sorted;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  int _getSeason(DateTime date) {
    return date.month >= 7 ? date.year : date.year - 1;
  }

  Future<void> _loadMatches({
    bool showLoading = true,
  }) async {
    if (!mounted) return;

    final currentRequestId = ++_requestId;

    final requestedDate = selectedDate;
    final requestedCompetition = selectedCompetition;

    if (showLoading) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final parameters = <String, String>{
        'date': _formatDate(requestedDate),
      };

      if (requestedCompetition != 'ALL') {
        final leagueId = competitionIds[requestedCompetition];

        if (leagueId == null) {
          throw Exception('رمز البطولة غير معروف.');
        }

        parameters['league'] = leagueId.toString();
        parameters['season'] = _getSeason(requestedDate).toString();
      }

      final endpoint = Uri.parse(
        '${ApiConfig.baseUrl}/api/fixtures',
      ).replace(
        queryParameters: parameters,
      );

      final result = await _matchService.fetchMatches(
        endpoint: endpoint,
      );

      if (!mounted || currentRequestId != _requestId) return;

      setState(() {
        matches = _sortMatches(result);
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted || currentRequestId != _requestId) return;

      // نحافظ على المباريات القديمة عند فشل التحديث التلقائي.
      if (!showLoading && matches.isNotEmpty) {
        debugPrint('RIFGOAL AUTO REFRESH ERROR: $error');
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  void _openMatchDetails(FootballMatch match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailsScreen(match: match),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _requestId++;

    _matchService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 12),

        DateSelector(
          selectedDate: selectedDate,
          onDateSelected: (date) {
            if (date == selectedDate) return;

            setState(() {
              selectedDate = date;
            });

            _loadMatches();
          },
        ),

        const SizedBox(height: 12),

        CompetitionSelector(
          selectedCompetition: selectedCompetition,
          onSelected: (competition) {
            if (competition == selectedCompetition) return;

            setState(() {
              selectedCompetition = competition;
            });

            _loadMatches();
          },
        ),

        const SizedBox(height: 12),

        Expanded(
          child: _buildMatchesContent(isDark),
        ),
      ],
    );
  }

  Widget _buildMatchesContent(bool isDark) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return _buildMessage(
        icon: Icons.wifi_off,
        title: 'تعذر تحميل المباريات',
        subtitle: errorMessage!,
        isDark: isDark,
        showRetry: true,
      );
    }

    if (matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMatches,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Icon(
              Icons.sports_soccer_outlined,
              size: 65,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'لا توجد مباريات في هذا اليوم',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'اسحب للأسفل لتحديث النتائج',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF8B949E)
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(matches[index], isDark);
        },
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    bool showRetry = false,
  }) {
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
            const SizedBox(height: 16),
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
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF8B949E)
                    : Colors.grey,
                fontSize: 13,
              ),
            ),
            if (showRetry) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadMatches,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(FootballMatch match, bool isDark) {
    final cardColor =
        isDark ? const Color(0xFF161B22) : Colors.white;

    final borderColor =
        isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB);

    const liveColor = Color(0xFFF85149);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openMatchDetails(match),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        FootballTranslations.league(match.leagueName),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF8B949E)
                              : Colors.blueGrey,
                        ),
                      ),
                    ),
                    Text(
                      _statusText(match),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: match.isLive
                            ? liveColor
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTeam(
                        name: match.homeTeam,
                        logo: match.homeLogo,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${match.homeScore ?? '-'} : ${match.awayScore ?? '-'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (match.isLive && match.elapsed != null)
                          Text(
                            "${match.elapsed}'",
                            style: const TextStyle(
                              color: liveColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: _buildTeam(
                        name: match.awayTeam,
                        logo: match.awayLogo,
                      ),
                    ),
                  ],
                ),
              ),
              if (match.stadium.isNotEmpty || match.referee.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    [
                      if (match.stadium.isNotEmpty) match.stadium,
                      if (match.referee.isNotEmpty)
                        'الحكم: ${match.referee}',
                    ].join(' • '),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF8B949E)
                          : Colors.grey,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'اضغط لعرض تفاصيل المباراة',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeam({
    required String name,
    required String logo,
  }) {
    final translatedName = FootballTranslations.team(name);

    return Column(
      children: [
        SizedBox(
          height: 42,
          width: 42,
          child: logo.isEmpty
              ? const Icon(Icons.shield_outlined, size: 35)
              : Image.network(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shield_outlined,
                      size: 35,
                    );
                  },
                ),
        ),
        const SizedBox(height: 6),
        Text(
          translatedName.isEmpty ? 'غير معروف' : translatedName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _statusText(FootballMatch match) {
    if (match.isLive) {
      return match.elapsed != null
          ? "مباشر ${match.elapsed}'"
          : 'مباشر';
    }

    if (match.isFinished) return 'انتهت';

    switch (match.status) {
      case 'NS':
        return 'لم تبدأ';
      case 'HT':
        return 'استراحة';
      case 'PST':
        return 'مؤجلة';
      case 'CANC':
        return 'ألغيت';
      case 'SUSP':
        return 'متوقفة';
      case 'TBD':
        return 'لم يحدد الموعد';
      default:
        return match.statusLong.isEmpty
            ? 'موعد المباراة'
            : match.statusLong;
    }
  }
}
