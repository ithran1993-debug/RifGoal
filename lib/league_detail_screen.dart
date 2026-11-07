import 'package:flutter/material.dart';

import 'api_config.dart';
import 'match_model.dart';
import 'match_service.dart';
import 'standing_model.dart';
import 'standings_service.dart';
import 'football_translations.dart';

class LeagueDetailScreen extends StatefulWidget {
  final int leagueId;
  final String leagueName;
  final String leagueLogo;
  final String country;

  const LeagueDetailScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
    this.leagueLogo = '',
    this.country = '',
  });

  @override
  State<LeagueDetailScreen> createState() =>
      _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final MatchService _matchService = MatchService();
  final StandingsService _standingsService = StandingsService();

  List<FootballMatch> matches = [];
  List<Standing> standings = [];

  bool matchesLoading = true;
  bool standingsLoading = true;

  String? matchesError;
  String? standingsError;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _loadMatches();
    _loadStandings();
  }

  int _getSeason() {
    final now = DateTime.now();
    return now.month >= 7 ? now.year : now.year - 1;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMatches() async {
    if (!mounted) return;

    setState(() {
      matchesLoading = true;
      matchesError = null;
    });

    try {
      final endpoint = Uri.parse(
        '${ApiConfig.baseUrl}/api/fixtures',
      ).replace(
        queryParameters: {
          'date': _formatDate(DateTime.now()),
          'league': widget.leagueId.toString(),
          'season': _getSeason().toString(),
        },
      );

      final result = await _matchService.fetchMatches(
        endpoint: endpoint,
      );

      if (!mounted) return;

      setState(() {
        matches = result;
        matchesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        matchesError =
            error.toString().replaceFirst('Exception: ', '');
        matchesLoading = false;
      });
    }
  }

  Future<void> _loadStandings() async {
    if (!mounted) return;

    setState(() {
      standingsLoading = true;
      standingsError = null;
    });

    try {
      final endpoint = Uri.parse(
        '${ApiConfig.baseUrl}/api/standings',
      ).replace(
        queryParameters: {
          'league': widget.leagueId.toString(),
          'season': _getSeason().toString(),
        },
      );

      final result = await _standingsService.fetchStandings(
        endpoint: endpoint,
      );

      if (!mounted) return;

      setState(() {
        standings = result;
        standingsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        standingsError =
            error.toString().replaceFirst('Exception: ', '');
        standingsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _matchService.dispose();
    _standingsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          FootballTranslations.league(widget.leagueName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.sports_soccer),
              text: 'المباريات',
            ),
            Tab(
              icon: Icon(Icons.leaderboard),
              text: 'الترتيب',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildLeagueHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchesTab(),
                _buildStandingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueHeader() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.leagueLogo.isEmpty
                ? Icon(
                    Icons.emoji_events_outlined,
                    color: primary,
                    size: 34,
                  )
                : Image.network(
                    widget.leagueLogo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.emoji_events_outlined,
                        color: primary,
                        size: 34,
                      );
                    },
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FootballTranslations.league(widget.leagueName),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.country.isEmpty
                      ? 'رقم البطولة: ${widget.leagueId}'
                      : '${widget.country} • رقم ${widget.leagueId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    if (matchesLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (matchesError != null) {
      return _buildError(matchesError!, _loadMatches);
    }

    if (matches.isEmpty) {
      return _buildEmpty(
        'لا توجد مباريات لهذه البطولة اليوم',
        Icons.sports_soccer_outlined,
        _loadMatches,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(matches[index]);
        },
      ),
    );
  }

  Widget _buildMatchCard(FootballMatch match) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  FootballTranslations.league(match.leagueName),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _statusText(match),
                style: TextStyle(
                  fontSize: 11,
                  color: match.isLive ? Colors.red : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: _teamWidget(
                  match.homeTeam,
                  match.homeLogo,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${match.homeScore ?? '-'} : ${match.awayScore ?? '-'}',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (match.isLive && match.elapsed != null)
                    Text(
                      "${match.elapsed}'",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              Expanded(
                child: _teamWidget(
                  match.awayTeam,
                  match.awayLogo,
                ),
              ),
            ],
          ),
          if (match.stadium.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              match.stadium,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // تم توحيد اسم الدالة مع الاستدعاءات.
  Widget _teamWidget(String name, String logo) {
    return Column(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: logo.isEmpty
              ? const Icon(
                  Icons.shield_outlined,
                  size: 34,
                )
              : Image.network(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shield_outlined,
                      size: 34,
                    );
                  },
                ),
        ),
        const SizedBox(height: 6),
        Text(
          FootballTranslations.team(name),
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

  Widget _buildStandingsTab() {
    if (standingsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (standingsError != null) {
      return _buildError(standingsError!, _loadStandings);
    }

    if (standings.isEmpty) {
      return _buildEmpty(
        'لا يوجد جدول ترتيب متاح لهذه البطولة',
        Icons.leaderboard_outlined,
        _loadStandings,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStandings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          _buildStandingsTable(),
        ],
      ),
    );
  }

  Widget _buildStandingsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 540,
            child: Column(
              children: [
                Container(
                  height: 44,
                  color: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Row(
                    children: [
                      _TableHeader('#', 35),
                      _TableHeader('الفريق', 175, alignStart: true),
                      _TableHeader('لعب', 45),
                      _TableHeader('فاز', 45),
                      _TableHeader('تعادل', 50),
                      _TableHeader('خسر', 45),
                      _TableHeader('النقاط', 65),
                    ],
                  ),
                ),
                ...standings.map(_buildStandingRow),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandingRow(Standing item) {
    final theme = Theme.of(context);

    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Center(
              child: Text(
                '${item.position}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 175,
            child: Row(
              children: [
                SizedBox(
                  width: 27,
                  height: 27,
                  child: item.teamLogo.isEmpty
                      ? const Icon(
                          Icons.shield_outlined,
                          size: 23,
                        )
                      : Image.network(
                          item.teamLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.shield_outlined,
                              size: 23,
                            );
                          },
                        ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    FootballTranslations.team(item.teamName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          _TableValue('${item.played}', 45),
          _TableValue('${item.won}', 45),
          _TableValue('${item.drawn}', 50),
          _TableValue('${item.lost}', 45),
          SizedBox(
            width: 65,
            child: Center(
              child: Text(
                '${item.points}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    String message,
    Future<void> Function() retry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'تعذر تحميل البيانات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(
    String message,
    IconData icon,
    Future<void> Function() retry,
  ) {
    return RefreshIndicator(
      onRefresh: retry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(
            icon,
            size: 55,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ),
        ],
      ),
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

class _TableHeader extends StatelessWidget {
  final String text;
  final double width;
  final bool alignStart;

  const _TableHeader(
    this.text,
    this.width, {
    this.alignStart = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign:
            alignStart ? TextAlign.start : TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TableValue extends StatelessWidget {
  final String text;
  final double width;

  const _TableValue(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}
