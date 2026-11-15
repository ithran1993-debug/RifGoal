import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const RifGoalApp());
}

class RifGoalApp extends StatelessWidget {
  const RifGoalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RifGoal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        primaryColor: const Color(0xFF22C55E),
        cardColor: const Color(0xFF1E293B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  static const String dataUrl =
      'https://ithran1993-debug.github.io/rifkoora/app_data.json';

  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMsg;
  Timer? _autoRefreshTimer;
  Timer? _secondTickTimer;
  Timer? _liveDetailsTimer;

  Map<String, dynamic> _settings = {'siteTitle': 'ريف جول', 'announcement': ''};
  List<dynamic> _leagues = [];
  List<dynamic> _matches = [];
  Map<String, dynamic> _standings = {};
  Map<String, dynamic> _topScorers = {};
  List<dynamic> _news = [];
  final Map<String, List>> _localNewsComments = {};

  late String _selectedLocalDate;
  late String _lastTodayIso;
  bool _liveOnly = false;
  String? _selectedStandingLeague;
  String? _selectedScorerLeague;

  @override
  void initState() {
    super.initState();
    _lastTodayIso = _toLocalIsoDate(DateTime.now());
    _selectedLocalDate = _lastTodayIso;
    _fetchAppData();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _fetchAppData(silent: true),
    );
    _secondTickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onSecondTick(),
    );
    _liveDetailsTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollLiveMatchesFromFotMob(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _secondTickTimer?.cancel();
    _liveDetailsTimer?.cancel();
    super.dispose();
  }

  void _onSecondTick() {
    if (!mounted) return;
    final now = DateTime.now();
    final todayIso = _toLocalIsoDate(now);
    bool needsRebuild = false;

    if (todayIso != _lastTodayIso) {
      _lastTodayIso = todayIso;
      _selectedLocalDate = todayIso;
      needsRebuild = true;
    }

    final nowUtc = now.toUtc();
    for (final item in _matches) {
      if (item is! Map) continue;
      final status = item['status']?.toString() ?? 'NS';
      if (status == 'NS' && item['timestamp'] != null) {
        final ts = item['timestamp'].toString();
        final start = DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z');
        if (start != null &&
            nowUtc.isAfter(start) &&
            nowUtc.difference(start).inHours < 2) {
          item['status'] = 'LIVE';
          item['scoreHome'] ??= 0;
          item['scoreAway'] ??= 0;
          needsRebuild = true;
        }
      } else if (['LIVE', '1H', '2H', 'HT'].contains(status)) {
        needsRebuild = true;
      }
    }

    if (needsRebuild) setState(() {});
  }

  String _computeLiveMinute(dynamic m) {
    final rawMin = (m['minute'] ?? '').toString();
    if (rawMin.contains('+')) return rawMin;
    final ts = (m['timestamp'] ?? '').toString();
    if (ts.isEmpty) return rawMin.isNotEmpty ? rawMin : '';
    final start = DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z');
    if (start == null) return rawMin;
    final diffMin = DateTime.now().toUtc().difference(start).inMinutes;
    if (diffMin < 0) return '';
    if (diffMin <= 45) return "${diffMin < 1 ? 1 : diffMin}'";
    if (diffMin <= 60) return 'استراحة';
    final secondHalf = diffMin - 15;
    if (secondHalf <= 90) return "$secondHalf'";
    if (secondHalf <= 105) return "90+${secondHalf - 90}'";
    return rawMin;
  }

  Future<void> _fetchSingleMatchDetails(dynamic m) async {
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      final uri = Uri.parse(
        'https://www.fotmob.com/api/matchDetails?matchId=$id&ccode3=MAR',
      );
      final res = await http.get(uri, headers: {
        'Accept-Language': 'ar-MA,ar;q=0.9',
        'Cookie': 'fotmob_lang=ar; ccode3=MAR',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return;
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      final header = json['header'] ?? {};
      final teams = header['teams'] is List ? header['teams'] : [];
      final statusObj = header['status'] ?? {};

      if (teams.length >= 2) {
        m['scoreHome'] = teams[0]['score'] ?? m['scoreHome'] ?? 0;
        m['scoreAway'] = teams[1]['score'] ?? m['scoreAway'] ?? 0;
        m['status'] = statusObj['finished'] == true
            ? 'FT'
            : (statusObj['started'] == true ? 'LIVE' : m['status']);
        m['minute'] = statusObj['liveTime']?['short'] ?? m['minute'];
      }

      final content = json['content'] ?? {};
      final rawEvents = content['matchFacts']?['events']?['events'] ?? [];
      final infoBox = content['matchFacts']?['infoBox'] ?? {};
      final topStats = content['stats']?['Periods']?['All']?['stats'] ?? [];
      final statsItems =
          (topStats is List && topStats.isNotEmpty) ? (topStats[0]['stats'] ?? []) : [];
      final lineup = content['lineup'] ?? {};

      final stadiumName = infoBox['Stadium']?['name']?.toString() ?? '';
      if (stadiumName.isNotEmpty) m['stadium'] = stadiumName;

      m['details'] = {
        'stadium': stadiumName,
        'referee': infoBox['Referee']?['text']?.toString() ?? '',
        'events': (rawEvents is List ? rawEvents : [])
            .where((e) => e['type'] == 'Goal' || e['type'] == 'Card')
            .map((e) => {
                  'time': e['timeStr'] ?? "${e['time']}'",
                  'type': e['type'] == 'Goal'
                      ? 'goal'
                      : (e['card'] == 'Red' ? 'red_card' : 'yellow_card'),
                  'player': e['player']?['name'] ?? e['nameStr'] ?? '',
                  'isHome': e['isHome'] == true,
                })
            .toList(),
        'stats': (statsItems is List ? statsItems : [])
            .map((s) => {
                  'title': s['title'] ?? '',
                  'home': (s['stats'] is List && s['stats'].isNotEmpty) ? s['stats'][0] : '',
                  'away': (s['stats'] is List && s['stats'].length > 1) ? s['stats'][1] : '',
                })
            .toList(),
        'lineups': {
          'home': (lineup['homeTeam']?['starters'] is List ? lineup['homeTeam']['starters'] : [])
              .map((p) => {'number': p['shirtNumber'], 'name': p['name']})
              .toList(),
          'away': (lineup['awayTeam']?['starters'] is List ? lineup['awayTeam']['starters'] : [])
              .map((p) => {'number': p['shirtNumber'], 'name': p['name']})
              .toList(),
        }
      };
    } catch (_) {}
  }

  Future<void> _pollLiveMatchesFromFotMob() async {
    final todayIso = _toLocalIsoDate(DateTime.now());
    final liveList = _matches
        .where((m) =>
            m is Map &&
            _getLocalMatchDate(m) == todayIso &&
            ['LIVE', '1H', '2H', 'HT'].contains(m['status']))
        .take(15)
        .toList();

    if (liveList.isEmpty) return;
    for (final m in liveList) {
      await _fetchSingleMatchDetails(m);
    }
    if (mounted) setState(() {});
  }

  String _toLocalIsoDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _getLocalMatchDate(dynamic match) {
    final ts = match['timestamp']?.toString();
    if (ts != null && ts.isNotEmpty) {
      final parsed = DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z');
      if (parsed != null) return _toLocalIsoDate(parsed);
    }
    return match['date']?.toString() ?? _selectedLocalDate;
  }

  String _getLocalMatchTime(dynamic match) {
    final ts = match['timestamp']?.toString();
    if (ts != null && ts.isNotEmpty) {
      final parsed =
          DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z')?.toLocal();
      if (parsed != null) {
        final h = parsed.hour.toString().padLeft(2, '0');
        final m = parsed.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
    }
    return match['time']?.toString() ?? '20:00';
  }

  Future<void> _fetchAppData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });
    }

    try {
      final uri = Uri.parse('$dataUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        setState(() {
          _settings = decoded['settings'] is Map
              ? Map<String, dynamic>.from(decoded['settings'])
              : _settings;
          _leagues = decoded['leagues'] is List ? decoded['leagues'] : [];
          _matches = decoded['matches'] is List ? decoded['matches'] : [];
          _standings = decoded['standings'] is Map
              ? Map<String, dynamic>.from(decoded['standings'])
              : {};
          _topScorers = decoded['topScorers'] is Map
              ? Map<String, dynamic>.from(decoded['topScorers'])
              : {};
          _news = decoded['news'] is List ? decoded['news'] : [];

          if (_standings.isNotEmpty &&
              (_selectedStandingLeague == null ||
                  !_standings.containsKey(_selectedStandingLeague))) {
            _selectedStandingLeague = _standings.keys.first;
          }
          if (_topScorers.isNotEmpty &&
              (_selectedScorerLeague == null ||
                  !_topScorers.containsKey(_selectedScorerLeague))) {
            _selectedScorerLeague = _topScorers.keys.first;
          }
          _isLoading = false;
        });

        _pollLiveMatchesFromFotMob();
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!silent) _errorMsg = 'تعذر تحديث البيانات، اسحب للأسفل للمحاولة مجدداً.';
      });
    }
  }

  void _openMatchDetailsSheet(dynamic m) async {
    await _fetchSingleMatchDetails(m);
    if (!mounted) return;
    setState(() {});

    final d = m['details'] ?? {};
    final events = d['events'] is List ? d['events'] as List : [];
    final stats = d['stats'] is List ? d['stats'] as List : [];
    final lineups = d['lineups'] ?? {};
    final homeStarters = lineups['home'] is List ? lineups['home'] as List : [];
    final awayStarters = lineups['away'] is List ? lineups['away'] as List : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                '🏆 ${m['league'] ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(m['homeLogo']?.toString()),
                        const SizedBox(height: 6),
                        Text(
                          m['home']?.toString() ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        m['status'] == 'NS'
                            ? _getLocalMatchTime(m)
                            : '${m['scoreHome'] ?? 0} - ${m['scoreAway'] ?? 0}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['LIVE', '1H', '2H', 'HT'].contains(m['status'])
                            ? 'مباشر ${_computeLiveMinute(m)}'
                            : (m['status'] == 'FT' ? 'انتهت' : 'لم تبدأ'),
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(m['awayLogo']?.toString()),
                        const SizedBox(height: 6),
                        Text(
                          m['away']?.toString() ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 26, color: Color(0xFF334155)),
              const Text('⏱️ أحداث المباراة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (events.isEmpty)
                const Text('لا توجد أحداث مسجلة بعد.',
                    style: TextStyle(color: Colors.grey))
              else
                ...events.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              e['isHome'] == true
                                  ? "${e['player']} (${e['time']})"
                                  : '',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Text(e['type'] == 'goal'
                              ? '⚽'
                              : (e['type'] == 'red_card' ? '🟥' : '🟨')),
                          Expanded(
                            child: Text(
                              e['isHome'] != true
                                  ? "(${e['time']}) ${e['player']}"
                                  : '',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    )),
              if (stats.isNotEmpty) ...[
                const Divider(height: 26, color: Color(0xFF334155)),
                const Text('📊 إحصائيات اللقاء',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ...stats.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${s['home']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${s['title']}',
                              style: const TextStyle(color: Colors.white70)),
                          Text('${s['away']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
              if (homeStarters.isNotEmpty || awayStarters.isNotEmpty) ...[
                const Divider(height: 26, color: Color(0xFF334155)),
                const Text('👕 التشكيلة الأساسية',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: homeStarters
                            .map((p) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                      '${p['number'] ?? ''} ${p['name'] ?? ''}',
                                      style: const TextStyle(fontSize: 12.5)),
                                ))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: awayStarters
                            .map((p) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                      '${p['name'] ?? ''} ${p['number'] ?? ''}',
                                      style: const TextStyle(fontSize: 12.5)),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _settings['siteTitle']?.toString().isNotEmpty == true
        ? _settings['siteTitle'].toString()
        : 'RifGoal';
    final announcement = _settings['announcement']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_soccer, color: Color(0xFF22C55E)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'مباشر',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchAppData();
              _pollLiveMatchesFromFotMob();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (announcement.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF0284C7)],
                ),
              ),
              child: Text(
                '📢 $announcement',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF22C55E)),
                  )
                : _errorMsg != null && _matches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMsg!, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _fetchAppData(),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : IndexedStack(
                        index: _currentIndex,
                        children: [
                          _buildMatchesTab(),
                          _buildStandingsTab(),
                          _buildScorersTab(),
                          _buildNewsTab(),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF22C55E),
        unselectedItemColor: const Color(0xFF94A3B8),
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'المباريات'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'الترتيب'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'الهدافون'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'الأخبار'),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    final liveMatches = _matches
        .where((m) => m is Map && ['LIVE', '1H', '2H', 'HT'].contains(m['status']))
        .toList();
    final displayedMatches = _liveOnly
        ? liveMatches
        : _matches
            .where((m) => m is Map && _getLocalMatchDate(m) == _selectedLocalDate)
            .toList();

    final Map<String, List<dynamic>> grouped = {};
    for (final m in displayedMatches) {
      final lg = m['league']?.toString() ?? 'بطولات متنوعة';
      grouped.putIfAbsent(lg, () => []).add(m);
    }

    final Map<String, int> orderMap = {};
    for (final l in _leagues) {
      if (l is Map && l['name'] != null) {
        orderMap[l['name'].toString()] = (l['order'] as num?)?.toInt() ?? 99;
      }
    }
    final sortedLeagues = grouped.keys.toList()
      ..sort((a, b) => (orderMap[a] ?? 99).compareTo(orderMap[b] ?? 99));

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchAppData();
        await _pollLiveMatchesFromFotMob();
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildWeekDaysStrip(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _liveOnly
                    ? '🔴 المباريات المباشرة (${displayedMatches.length})'
                    : '📅 $_selectedLocalDate (${displayedMatches.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              InkWell(
                onTap: () => setState(() => _liveOnly = !_liveOnly),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _liveOnly
                        ? Colors.red.withOpacity(0.2)
                        : const Color(0xFF1E293B),
                    border: Border.all(
                      color: _liveOnly ? Colors.red : const Color(0xFF334155),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'مباشر (${liveMatches.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sortedLeagues.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'لا توجد مباريات مجدولة في هذا اليوم.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...sortedLeagues.map((lg) => _buildLeagueCard(lg, grouped[lg]!)),
        ],
      ),
    );
  }

  Widget _buildWeekDaysStrip() {
    const daysAr = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final offset = index - 2;
          final date = DateTime.now().add(Duration(days: offset));
          final iso = _toLocalIsoDate(date);
          final label = offset == 0
              ? 'اليوم'
              : offset == 1
                  ? 'غداً'
                  : offset == -1
                      ? 'أمس'
                      : offset == -2
                          ? 'أول أمس'
                          : daysAr[date.weekday % 7];
          final count = _matches.where((m) => m is Map && _getLocalMatchDate(m) == iso).length;
          final isSelected = !_liveOnly && iso == _selectedLocalDate;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLocalDate = iso;
                _liveOnly = false;
              });
            },
            child: Container(
              width: 86,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(iso.substring(5), style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$count', style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeagueCard(String leagueName, List<dynamic> leagueMatches) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF273549),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🏆 $leagueName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${leagueMatches.length}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
          ...leagueMatches.map((m) => _buildMatchRow(m)),
        ],
      ),
    );
  }

  Widget _buildMatchRow(dynamic m) {
    final status = m['status']?.toString() ?? 'NS';
    final isLive = ['LIVE', '1H', '2H', 'HT'].contains(status);
    final localTime = _getLocalMatchTime(m);
    final channel = m['channel']?.toString() ?? '';
    final commentator = m['commentator']?.toString() ?? '';
    final stadium = m['stadium']?.toString() ?? '';
    final pulse = DateTime.now().second % 2 == 0;

    final meta = <String>[
      if (channel.isNotEmpty) '📺 $channel',
      if (commentator.isNotEmpty) '🎙️ $commentator',
      if (stadium.isNotEmpty) '🏟️ $stadium',
    ];

    return InkWell(
      onTap: () => _openMatchDetailsSheet(m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.6)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          m['home']?.toString() ?? '',
                          textAlign: TextAlign.left,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _teamLogo(m['homeLogo']?.toString()),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLive ? Colors.redAccent : const Color(0xFF334155),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (status == 'NS')
                        Text(localTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))
                      else
                        Text(
                          '${m['scoreHome'] ?? 0} - ${m['scoreAway'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        isLive
                            ? 'مباشر ${_computeLiveMinute(m)}${pulse ? ' •' : ''}'
                            : status == 'FT'
                                ? 'انتهت'
                                : 'لم تبدأ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLive
                              ? Colors.redAccent
                              : status == 'FT'
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF60A5FA),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _teamLogo(m['awayLogo']?.toString()),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          m['away']?.toString() ?? '',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meta.join(' • '),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _teamLogo(String? url) {
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
        radius: 13,
        backgroundColor: Color(0xFF334155),
        child: Icon(Icons.shield, size: 15, color: Colors.white70),
      );
    }
    return ClipOval(
      child: Image.network(
        url,
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const CircleAvatar(
          radius: 13,
          backgroundColor: Color(0xFF334155),
          child: Icon(Icons.shield, size: 15, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildStandingsTab() {
    final leagueNames = _standings.keys.toList();
    if (leagueNames.isEmpty) {
      return const Center(child: Text('لا تتوفر جداول ترتيب حالياً.'));
    }

    final rows = (_standings[_selectedStandingLeague] is List)
        ? (_standings[_selectedStandingLeague] as List)
        : [];

    return RefreshIndicator(
      onRefresh: () => _fetchAppData(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStandingLeague,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                items: leagueNames
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStandingLeague = val),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('الفريق')),
                  DataColumn(label: Text('لعب')),
                  DataColumn(label: Text('ف')),
                  DataColumn(label: Text('ت')),
                  DataColumn(label: Text('خ')),
                  DataColumn(label: Text('أهداف')),
                  DataColumn(label: Text('نقاط')),
                ],
                rows: rows.map((r) {
                  return DataRow(cells: [
                    DataCell(Text('${r['rank']}')),
                    DataCell(Row(
                      children: [
                        _teamLogo(r['logo']?.toString()),
                        const SizedBox(width: 8),
                        Text(r['team']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )),
                    DataCell(Text('${r['played']}')),
                    DataCell(Text('${r['win']}')),
                    DataCell(Text('${r['draw']}')),
                    DataCell(Text('${r['lose']}')),
                    DataCell(Text('${r['gf']}:${r['ga']}')),
                    DataCell(Text('${r['points']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Color(0xFF22C55E)))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorersTab() {
    final leagueNames = _topScorers.keys.toList();
    if (leagueNames.isEmpty) {
      return const Center(child: Text('لا تتوفر بيانات الهدافين حالياً.'));
    }

    final rows = (_topScorers[_selectedScorerLeague] is List)
        ? (_topScorers[_selectedScorerLeague] as List)
        : [];

    return RefreshIndicator(
      onRefresh: () => _fetchAppData(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedScorerLeague,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                items: leagueNames
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedScorerLeague = val),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: rows.map((r) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0F172A),
                    child: Text(
                      '${r['rank']}',
                      style: const TextStyle(
                          color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(r['player']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(r['team']?.toString() ?? '',
                      style: const TextStyle(color: Color(0xFF94A3B8))),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${r['goals']} هدف',
                      style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _openNewsDetailsSheet(dynamic item, int idx) {
    final newsId = (item['id'] ?? idx).toString();
    final img = (item['image'] ?? item['img'] ?? '').toString();
    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final serverComments = item['comments'] is List ? item['comments'] as List : [];
          final userComments = _localNewsComments[newsId] ?? [];
          final allComments = [...serverComments, ...userComments];

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              maxChildSize: 0.94,
              builder: (_, scrollCtrl) => Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    if (img.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          img,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      '${item['league'] ?? 'أخبار الرياضة'} • ${item['date'] ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (item['content'] ?? item['summary'] ?? '').toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14.5,
                        height: 1.7,
                      ),
                    ),
                    const Divider(height: 28, color: Color(0xFF334155)),
                    Text(
                      '💬 التعليقات (${allComments.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (allComments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'لا توجد تعليقات بعد. كن أول من يعلّق!',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    else
                      ...allComments.map((c) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '👤 ${c['author'] ?? 'زائر'}',
                                      style: const TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      c['time']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c['text']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ],
                            ),
                          )),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              hintText: 'اسمك (اختياري)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: commentCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'اكتب تعليقك هنا...',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                final txt = commentCtrl.text.trim();
                                if (txt.isEmpty) return;
                                final now = DateTime.now();
                                final timeStr =
                                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                                _localNewsComments.putIfAbsent(newsId, () => []).add({
                                  'author': nameCtrl.text.trim().isEmpty
                                      ? 'زائر'
                                      : nameCtrl.text.trim(),
                                  'text': txt,
                                  'time': timeStr,
                                });
                                commentCtrl.clear();
                                setModalState(() {});
                                setState(() {});
                              },
                              child: const Text(
                                'إرسال التعليق',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsTab() {
    if (_news.isEmpty) {
      return const Center(child: Text('لا توجد أخبار منشورة حالياً.'));
    }

    return RefreshIndicator(
      onRefresh: () => _fetchAppData(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _news.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final item = _news[idx];
          final newsId = (item['id'] ?? idx).toString();
          final img = (item['image'] ?? item['img'] ?? '').toString();
          final commentsCount =
              (item['comments'] is List ? (item['comments'] as List).length : 0) +
                  (_localNewsComments[newsId]?.length ?? 0);

          return InkWell(
            onTap: () => _openNewsDetailsSheet(item, idx),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (img.isNotEmpty)
                    Image.network(
                      img,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['league']?.toString() ?? 'أخبار الرياضة',
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['title']?.toString() ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📅 ${item['date'] ?? ''}',
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 12),
                            ),
                            Text(
                              '💬 $commentsCount • اقرأ التفاصيل ›',
                              style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
