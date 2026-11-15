import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const RifGoalApp());

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
        ),
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
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

  int _tab = 0;
  bool _loading = true;
  bool _liveOnly = false;
  late String _selectedDate;
  late String _todayIso;
  String? _standingLeague;
  String? _scorerLeague;

  Map _settings = {'siteTitle': 'ريف جول', 'announcement': ''};
  List _leagues = [];
  List _matches = [];
  Map _standings = {};
  Map _scorers = {};
  List _news = [];

  Timer? _syncTimer;
  Timer? _secTimer;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _todayIso = _isoDate(DateTime.now());
    _selectedDate = _todayIso;
    _fetchData();

    _syncTimer = Timer.periodic(
        const Duration(seconds: 60), (_) => _fetchData(silent: true));
    _secTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _liveTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _pollLive());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _secTimer?.cancel();
    _liveTimer?.cancel();
    super.dispose();
  }

  String _isoDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _matchDate(Map m) {
    final ts = m['timestamp']?.toString() ?? '';
    final p = ts.isNotEmpty
        ? DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z')
        : null;
    return p != null ? _isoDate(p) : (m['date']?.toString() ?? _selectedDate);
  }

  String _matchTime(Map m) {
    final ts = m['timestamp']?.toString() ?? '';
    final p = ts.isNotEmpty
        ? DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z')?.toLocal()
        : null;
    return p != null
        ? '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}'
        : (m['time']?.toString() ?? '20:00');
  }

  String _liveMinute(Map m) {
    final raw = (m['minute'] ?? '').toString();
    if (raw.contains('+')) return raw;
    final ts = (m['timestamp'] ?? '').toString();
    final start = ts.isNotEmpty
        ? DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z')
        : null;
    if (start == null) return raw.isNotEmpty ? raw : 'مباشر';
    final diff = DateTime.now().toUtc().difference(start).inMinutes;
    if (diff < 0) return 'لم تبدأ';
    if (diff <= 45) return "${diff < 1 ? 1 : diff}'";
    if (diff <= 60) return 'استراحة';
    final h2 = diff - 15;
    if (h2 <= 90) return "$h2'";
    if (h2 <= 105) return "90+${h2 - 90}'";
    return raw.isNotEmpty ? raw : 'مباشر';
  }

  void _onTick() {
    if (!mounted) return;
    final now = DateTime.now();
    final today = _isoDate(now);
    bool refresh = false;

    if (today != _todayIso) {
      _todayIso = today;
      _selectedDate = today;
      refresh = true;
    }

    final utc = now.toUtc();
    for (final m in _matches) {
      if (m is! Map) continue;
      final st = m['status']?.toString() ?? 'NS';
      if (st == 'NS' && m['timestamp'] != null) {
        final ts = m['timestamp'].toString();
        final start = DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z');
        if (start != null &&
            utc.isAfter(start) &&
            utc.difference(start).inHours < 2) {
          m['status'] = 'LIVE';
          m['scoreHome'] ??= 0;
          m['scoreAway'] ??= 0;
          refresh = true;
        }
      } else if (['LIVE', '1H', '2H', 'HT'].contains(st)) {
        refresh = true;
      }
    }
    if (refresh) setState(() {});
  }

  Future<void> _fetchMatchDetails(Map m) async {
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse('https://www.fotmob.com/api/matchDetails?matchId=$id&ccode3=MAR'),
        headers: {'Accept-Language': 'ar-MA,ar;q=0.9', 'Cookie': 'fotmob_lang=ar; ccode3=MAR'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final j = jsonDecode(utf8.decode(res.bodyBytes));
      final teams = j['header']?['teams'] ?? [];
      final st = j['header']?['status'] ?? {};
      if (teams is List && teams.length >= 2) {
        m['scoreHome'] = teams[0]['score'] ?? m['scoreHome'] ?? 0;
        m['scoreAway'] = teams[1]['score'] ?? m['scoreAway'] ?? 0;
        m['status'] = st['finished'] == true
            ? 'FT'
            : (st['started'] == true ? 'LIVE' : m['status']);
        m['minute'] = st['liveTime']?['short'] ?? m['minute'];
      }

      final content = j['content'] ?? {};
      final events = content['matchFacts']?['events']?['events'] ?? [];
      final info = content['matchFacts']?['infoBox'] ?? {};
      final periods = content['stats']?['Periods']?['All']?['stats'] ?? [];
      final stats = (periods is List && periods.isNotEmpty) ? (periods[0]['stats'] ?? []) : [];
      final lineup = content['lineup'] ?? {};

      m['details'] = {
        'stadium': info['Stadium']?['name'] ?? '',
        'referee': info['Referee']?['text'] ?? '',
        'events': (events is List ? events : [])
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
        'stats': (stats is List ? stats : [])
            .map((s) => {
                  'title': s['title'] ?? '',
                  'home': (s['stats'] is List && s['stats'].isNotEmpty) ? s['stats'][0] : '',
                  'away': (s['stats'] is List && s['stats'].length > 1) ? s['stats'][1] : '',
                })
            .toList(),
        'homeLineup': (lineup['homeTeam']?['starters'] is List ? lineup['homeTeam']['starters'] : [])
            .map((p) => '${p['shirtNumber'] ?? ''} ${p['name'] ?? ''}')
            .toList(),
        'awayLineup': (lineup['awayTeam']?['starters'] is List ? lineup['awayTeam']['starters'] : [])
            .map((p) => '${p['shirtNumber'] ?? ''} ${p['name'] ?? ''}')
            .toList(),
      };
    } catch (_) {}
  }

  Future<void> _pollLive() async {
    final today = _isoDate(DateTime.now());
    final live = _matches
        .where((m) =>
            m is Map &&
            _matchDate(m) == today &&
            ['LIVE', '1H', '2H', 'HT'].contains(m['status']))
        .take(15)
        .toList();
    if (live.isEmpty) return;
    for (final m in live) {
      await _fetchMatchDetails(m as Map);
    }
    if (mounted) setState(() {});
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await http
          .get(Uri.parse('$dataUrl?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 && mounted) {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _settings = d['settings'] is Map ? d['settings'] : _settings;
          _leagues = d['leagues'] is List ? d['leagues'] : [];
          _matches = d['matches'] is List ? d['matches'] : [];
          _standings = d['standings'] is Map ? d['standings'] : {};
          _scorers = d['topScorers'] is Map ? d['topScorers'] : {};
          _news = d['news'] is List ? d['news'] : [];
          if (_standings.isNotEmpty && !_standings.containsKey(_standingLeague)) {
            _standingLeague = _standings.keys.first.toString();
          }
          if (_scorers.isNotEmpty && !_scorers.containsKey(_scorerLeague)) {
            _scorerLeague = _scorers.keys.first.toString();
          }
          _loading = false;
        });
        _pollLive();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetails(Map m) async {
    await _fetchMatchDetails(m);
    if (!mounted) return;
    setState(() {});
    final d = m['details'] is Map ? m['details'] : {};
    final events = d['events'] is List ? d['events'] : [];
    final stats = d['stats'] is List ? d['stats'] : [];
    final hLine = d['homeLineup'] is List ? d['homeLineup'] : [];
    final aLine = d['awayLineup'] is List ? d['awayLineup'] : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        builder: (_, ctrl) => Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(16),
            children: [
              Text('🏆 ${m['league'] ?? ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: Text(m['home']?.toString() ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text(
                    m['status'] == 'NS'
                        ? _matchTime(m)
                        : '${m['scoreHome'] ?? 0} - ${m['scoreAway'] ?? 0}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  Expanded(
                      child: Text(m['away']?.toString() ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              const Divider(height: 24, color: Color(0xFF334155)),
              const Text('⏱️ الأحداث',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (events.isEmpty)
                const Text('لا توجد أحداث مسجلة بعد',
                    style: TextStyle(color: Colors.grey))
              else
                ...events.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e['isHome'] == true
                              ? "${e['player']} (${e['time']})"
                              : ''),
                          Text(e['type'] == 'goal' ? '⚽' : '🟨'),
                          Text(e['isHome'] != true
                              ? "(${e['time']}) ${e['player']}"
                              : ''),
                        ],
                      ),
                    )),
              if (stats.isNotEmpty) ...[
                const Divider(height: 24, color: Color(0xFF334155)),
                const Text('📊 الإحصائيات',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...stats.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${s['home']}'),
                          Text('${s['title']}',
                              style: const TextStyle(color: Colors.white70)),
                          Text('${s['away']}'),
                        ],
                      ),
                    )),
              ],
              if (hLine.isNotEmpty || aLine.isNotEmpty) ...[
                const Divider(height: 24, color: Color(0xFF334155)),
                const Text('👕 التشكيلة الأساسية',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                hLine.map((p) => Text(p.toString())).toList())),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children:
                                aLine.map((p) => Text(p.toString())).toList())),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo(String? url) {
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
          radius: 13,
          backgroundColor: Color(0xFF334155),
          child: Icon(Icons.shield, size: 14));
    }
    return ClipOval(
      child: Image.network(url,
          width: 26,
          height: 26,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const CircleAvatar(
              radius: 13,
              backgroundColor: Color(0xFF334155),
              child: Icon(Icons.shield, size: 14))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ann = _settings['announcement']?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_soccer, color: Color(0xFF22C55E)),
            const SizedBox(width: 8),
            Text(_settings['siteTitle']?.toString() ?? 'RifGoal',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _fetchData();
                _pollLive();
              }),
        ],
      ),
      body: Column(
        children: [
          if (ann.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF16A34A),
              child: Text('📢 $ann',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF22C55E)))
                : IndexedStack(
                    index: _tab,
                    children: [
                      _matchesTab(),
                      _standingsTab(),
                      _scorersTab(),
                      _newsTab(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF22C55E),
        unselectedItemColor: const Color(0xFF94A3B8),
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'المباريات'),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard), label: 'الترتيب'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'الهدافون'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'الأخبار'),
        ],
      ),
    );
  }

  Widget _matchesTab() {
    final live = _matches
        .where((m) =>
            m is Map && ['LIVE', '1H', '2H', 'HT'].contains(m['status']))
        .toList();
    final list = _liveOnly
        ? live
        : _matches
            .where((m) => m is Map && _matchDate(m) == _selectedDate)
            .toList();

    final Map grouped = {};
    for (final m in list) {
      final lg = m['league']?.toString() ?? 'أخرى';
      grouped.putIfAbsent(lg, () => []).add(m);
    }

    const days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchData();
        await _pollLive();
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, idx) {
                final off = idx - 2;
                final d = DateTime.now().add(Duration(days: off));
                final iso = _isoDate(d);
                final lbl = off == 0
                    ? 'اليوم'
                    : off == 1
                        ? 'غداً'
                        : off == -1
                            ? 'أمس'
                            : off == -2
                                ? 'أول أمس'
                                : days[d.weekday % 7];
                final sel = !_liveOnly && iso == _selectedDate;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = iso;
                    _liveOnly = false;
                  }),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lbl,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(iso.substring(5),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📅 $_selectedDate (${list.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ActionChip(
                label: Text('🔴 مباشر (${live.length})'),
                backgroundColor:
                    _liveOnly ? Colors.red.withOpacity(0.3) : null,
                onPressed: () => setState(() => _liveOnly = !_liveOnly),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (grouped.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('لا توجد مباريات في هذا اليوم',
                      style: TextStyle(color: Colors.grey))),
            )
          else
            ...grouped.keys.map((lg) {
              final arr = grouped[lg] as List;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF273549),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('🏆 $lg',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${arr.length}'),
                        ],
                      ),
                    ),
                    ...arr.map((item) {
                      final m = item as Map;
                      final st = m['status']?.toString() ?? 'NS';
                      final isLive = ['LIVE', '1H', '2H', 'HT'].contains(st);
                      final pulse = DateTime.now().second % 2 == 0;
                      return InkWell(
                        onTap: () => _openDetails(m),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                      child: Text(m['home']?.toString() ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 8),
                                  _logo(m['homeLogo']?.toString()),
                                ],
                              )),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    Text(
                                      st == 'NS'
                                          ? _matchTime(m)
                                          : '${m['scoreHome'] ?? 0} - ${m['scoreAway'] ?? 0}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15),
                                    ),
                                    Text(
                                      isLive
                                          ? '${_liveMinute(m)}${pulse ? ' •' : ''}'
                                          : (st == 'FT' ? 'انتهت' : 'لم تبدأ'),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isLive
                                              ? Colors.redAccent
                                              : Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                  child: Row(
                                children: [
                                  _logo(m['awayLogo']?.toString()),
                                  const SizedBox(width: 8),
                                  Flexible(
                                      child: Text(m['away']?.toString() ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                              )),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _standingsTab() {
    if (_standings.isEmpty) return const Center(child: Text('لا يوجد ترتيب'));
    final keys = _standings.keys.map((e) => e.toString()).toList();
    final rows = _standings[_standingLeague] is List
        ? (_standings[_standingLeague] as List)
        : [];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        DropdownButton<String>(
          value: _standingLeague,
          isExpanded: true,
          items: keys
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) => setState(() => _standingLeague = v),
        ),
        ...rows.map((r) => ListTile(
              leading: Text('${r['rank']}'),
              title: Text(r['team']?.toString() ?? ''),
              trailing: Text('لعب ${r['played']} | ${r['points']} ن',
                  style: const TextStyle(
                      color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
            )),
      ],
    );
  }

  Widget _scorersTab() {
    if (_scorers.isEmpty) return const Center(child: Text('لا يوجد هدافون'));
    final keys = _scorers.keys.map((e) => e.toString()).toList();
    final rows =
        _scorers[_scorerLeague] is List ? (_scorers[_scorerLeague] as List) : [];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        DropdownButton<String>(
          value: _scorerLeague,
          isExpanded: true,
          items: keys
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) => setState(() => _scorerLeague = v),
        ),
        ...rows.map((r) => ListTile(
              leading: Text('${r['rank']}'),
              title: Text(r['player']?.toString() ?? ''),
              subtitle: Text(r['team']?.toString() ?? ''),
              trailing: Text('${r['goals']} هدف',
                  style: const TextStyle(
                      color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
            )),
      ],
    );
  }

  Widget _newsTab() {
    if (_news.isEmpty) return const Center(child: Text('لا توجد أخبار'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _news.length,
      itemBuilder: (_, i) {
        final n = _news[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(n['title']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(n['summary']?.toString() ?? ''),
          ),
        );
      },
    );
  }
}
