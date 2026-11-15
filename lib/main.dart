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
  List> _matches = [];
  Map<String, dynamic> _standings = {};
  Map<String, dynamic> _topScorers = {};
  List<dynamic> _news = [];

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

    // 1. تحديث القائمة المعتمدة من GitHub كل 60 ثانية
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _fetchAppData(silent: true),
    );

    // 2. عدّاد لحظي كل 1 ثانية لتحريك الدقائق الحية وتجديد شريط الأيام عند منتصف الليل
    _secondTickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onSecondTick(),
    );

    // 3. تحديث فوري للأهداف والنتائج والتفاصيل من FotMob كل 15 ثانية للمباريات الجارية
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

    // تجديد شريط الأيام تلقائياً عند دخول يوم جديد
    if (todayIso != _lastTodayIso) {
      _lastTodayIso = todayIso;
      _selectedLocalDate = todayIso;
      needsRebuild = true;
    }

    // تفعيل حالة LIVE تلقائياً عند حلول موعد المباراة + تحديث الدقائق الحية
    final nowUtc = now.toUtc();
    for (final m in _matches) {
      final status = m['status']?.toString() ?? 'NS';
      if (status == 'NS' && m['timestamp'] != null) {
        final ts = m['timestamp'].toString();
        final start = DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z');
        if (start != null &&
            nowUtc.isAfter(start) &&
            nowUtc.difference(start).inHours < 2) {
          m['status'] = 'LIVE';
          m['scoreHome'] ??= 0;
          m['scoreAway'] ??= 0;
          needsRebuild = true;
        }
      } else if (['LIVE', '1H', '2H', 'HT'].contains(status)) {
        needsRebuild = true;
      }
    }

    if (needsRebuild) {
      setState(() {});
    }
  }

  String _computeLiveMinute(Map<String, dynamic> m) {
    final rawMin = (m['minute'] ?? '').toString();
    if (rawMin.contains('+')) return rawMin;

    final ts = (m['timestamp'] ?? '').toString();
    if (ts.isEmpty) return rawMin.isNotEmpty ? rawMin : 'مباشر';

    final start = DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z');
    if (start == null) return rawMin.isNotEmpty ? rawMin : 'مباشر';

    final diffMin = DateTime.now().toUtc().difference(start).inMinutes;
    if (diffMin < 0) return 'لم تبدأ';
    if (diffMin <= 45) return "${diffMin < 1 ? 1 : diffMin}'";
    if (diffMin <= 60) return 'استراحة';

    final secondHalf = diffMin - 15;
    if (secondHalf <= 90) return "$secondHalf'";
    if (secondHalf <= 105) return "90+${secondHalf - 90}'";
    return rawMin.isNotEmpty ? rawMin : 'مباشر';
  }

  Future<void> _fetchSingleMatchDetails(Map<String, dynamic> m) async {
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
      final teams = (header['teams'] as List?) ?? [];
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
      final rawEvents =
          (content['matchFacts']?['events']?['events'] as List?) ?? [];
      final infoBox = content['matchFacts']?['infoBox'] ?? {};
      final topStats =
          (content['stats']?['Periods']?['All']?['stats'] as List?) ?? [];
      final statsItems =
          topStats.isNotEmpty ? ((topStats[0]['stats'] as List?) ?? []) : [];
      final lineup = content['lineup'] ?? {};

      final stadiumName = infoBox['Stadium']?['name']?.toString() ?? '';
      if (stadiumName.isNotEmpty) m['stadium'] = stadiumName;

      m['details'] = {
        'stadium': stadiumName,
        'referee': infoBox['Referee']?['text']?.toString() ?? '',
        'events': rawEvents
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
        'stats': statsItems
            .map((s) => {
                  'title': s['title'] ?? '',
                  'home': (s['stats'] as List?)?[0] ?? '',
                  'away': (s['stats'] as List?)?[1] ?? '',
                })
            .toList(),
        'lineups': {
          'home': ((lineup['homeTeam']?['starters'] as List?) ?? [])
              .map((p) => {'number': p['shirtNumber'], 'name': p['name']})
              .toList(),
          'away': ((lineup['awayTeam']?['starters'] as List?) ?? [])
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

  String _getLocalMatchDate(Map<String, dynamic> match) {
    final ts = match['timestamp']?.toString();
    if (ts != null && ts.isNotEmpty) {
      final parsed = DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z');
      if (parsed != null) return _toLocalIsoDate(parsed);
    }
    return match['date']?.toString() ?? _selectedLocalDate;
  }

  String _getLocalMatchTime(Map<String, dynamic> match) {
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
        final rawMatches = (decoded['matches'] as List?) ?? [];
        setState(() {
          _settings = Map<String, dynamic>.from(decoded['settings'] ?? _settings);
          _leagues = List<dynamic>.from(decoded['leagues'] ?? []);
          _matches = rawMatches
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _standings = Map<String, dynamic>.from(decoded['standings'] ?? {});
          _topScorers = Map<String, dynamic>.from(decoded['topScorers'] ?? {});
          _news = List<dynamic>.from(decoded['news'] ?? []);

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

  void _openMatchDetailsSheet(Map<String, dynamic> m) async {
    await _fetchSingleMatchDetails(m);
    if (!mounted) return;
    setState(() {});

    final d = Map<String, dynamic>.from(m['details'] ?? {});
    final events = (d['events'] as List?) ?? [];
    final stats = (d['stats'] as List?) ?? [];
    final lineups = Map<String, dynamic>.from(d['lineups'] ?? {});
    final homeStarters = (lineups['home'] as List?) ?? [];
    final awayStarters = (lineups['away'] as List?) ?? [];

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
                            ? _computeLiveMinute(m)
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
              if ((d['stadium']?.toString() ?? '').isNotEmpty ||
                  (d['referee']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '${(d['stadium'] ?? '').isNotEmpty ? '🏟️ ${d['stadium']} ' : ''}${(d['referee'] ?? '').isNotEmpty ? '• 👨‍⚖️ ${d['referee']}' : ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
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

  // ==================== 1. تبويب المباريات ====================
  Widget _buildMatchesTab() {
    final liveMatches = _matches
        .where((m) => ['LIVE', '1H', '2H', 'HT'].contains(m['status']))
        .toList();
    final displayedMatches = _liveOnly
        ? liveMatches
        : _matches
            .where((m) => _getLocalMatchDate(m) == _selectedLocalDate)
            .toList();

    final Map<String, List>> grouped = {};
    for (final m in displayedMatches) {
      final lg = m['league']?.toString() ?? 'بطولات متنوعة';
      grouped.putIfAbsent(lg, () => []).add(m);
    }

    final Map<String, int> orderMap = {
      for (final l in _leagues)
        if (l['name'] != null)
          l['name'].toString(): (l['order'] as num?)?.toInt() ?? 99
    };
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
        itemCount: 10, // 10 أيام كاملة: أمسين + اليوم + 7 أيام قادمة (تشمل الجمعة والسبت والأحد)
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final offset = index - 2; // -2 أول أمس، -1 أمس، 0 اليوم، +1..+7 الأيام القادمة
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
          final count = _matches.where((m) => _getLocalMatchDate(m) == iso).length;
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

  Widget _buildLeagueCard(String leagueName, List> leagueMatches) {
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

  Widget _buildMatchRow(Map<String, dynamic> m) {
    final status = m['status']?.toString() ?? 'NS';
    final isLive = ['LIVE', '1H', '2H', 'HT'].contains(status);
    final localTime = _getLocalMatchTime(m);
    final channel = m['channel']?.toString() ?? '';
    final commentator = m['commentator']?.toString() ?? '';
    final stadium = m['stadium']?.toString() ?? '';
    final secPulse = DateTime.now().second % 2 == 0;

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
                            ? '${_computeLiveMinute(m)}${secPulse ? ' •' : ''}'
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

  // ==================== 2. تبويب الترتيب ====================
  Widget _buildStandingsTab() {
    final leagueNames = _standings.keys.toList();
    if (leagueNames.isEmpty) {
      return const Center(child: Text('لا تتوفر جداول ترتيب حالياً.'));
    }

    final rows = List<dynamic>.from(_standings[_selectedStandingLeague] ?? []);

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

  // ==================== 3. تبويب الهدافين ====================
  Widget _buildScorersTab() {
    final leagueNames = _topScorers.keys.toList();
    if (leagueNames.isEmpty) {
      return const Center(child: Text('لا تتوفر بيانات الهدافين حالياً.'));
    }

    final rows = List<dynamic>.from(_topScorers[_selectedScorerLeague] ?? []);

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

  // ==================== 4. تبويب الأخبار ====================
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
          final img = item['image']?.toString() ?? '';
          return Container(
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
                    height: 180,
                    fit: BoxFit.cover,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['summary']?.toString() ?? '',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '📅 ${item['date'] ?? ''}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
