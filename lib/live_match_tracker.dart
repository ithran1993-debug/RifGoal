import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveMatchTracker {
  Timer? _secondTimer;
  Timer? _livePollTimer;

  /// حساب الدقيقة الحية كل ثانية محلياً دون طلبات إنترنت
  String computeLiveMinute(Map<String, dynamic> m) {
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

  /// تشغيل التحديث اللحظي: كل ثانية للدقائق + كل 15 ثانية للأهداف والتفاصيل
  void start({
    required List> matches,
    required void Function() onUiRefresh,
  }) {
    stop();

    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final nowUtc = DateTime.now().toUtc();
      for (final m in matches) {
        if (m['status'] == 'NS' && m['timestamp'] != null) {
          final ts = m['timestamp'].toString();
          final start = DateTime.tryParse(ts.endsWith('Z') ? ts : '${ts}Z');
          if (start != null &&
              nowUtc.isAfter(start) &&
              nowUtc.difference(start).inHours < 2) {
            m['status'] = 'LIVE';
            m['scoreHome'] ??= 0;
            m['scoreAway'] ??= 0;
          }
        }
      }
      onUiRefresh();
    });

    _pollLiveDetails(matches, onUiRefresh);
    _livePollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollLiveDetails(matches, onUiRefresh),
    );
  }

  /// جلب النتيجة والأحداث والإحصائيات والتشكيلة مباشرة من FotMob
  Future<void> fetchSingleMatchDetails(Map<String, dynamic> m) async {
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      final uri = Uri.parse(
        'https://www.fotmob.com/api/matchDetails?matchId=$id&ccode3=MAR',
      );
      final res = await http.get(uri, headers: {
        'Accept-Language': 'ar-MA,ar;q=0.9',
        'Cookie': 'fotmob_lang=ar; ccode3=MAR',
      });

      if (res.statusCode != 200) return;
      final json = jsonDecode(res.body);
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
      final rawEvents = (content['matchFacts']?['events']?['events'] as List?) ?? [];
      final infoBox = content['matchFacts']?['infoBox'] ?? {};
      final topStats = (content['stats']?['Periods']?['All']?['stats'] as List?) ?? [];
      final statsItems = topStats.isNotEmpty ? ((topStats[0]['stats'] as List?) ?? []) : [];
      final lineup = content['lineup'] ?? {};

      m['details'] = {
        'stadium': infoBox['Stadium']?['name'] ?? '',
        'referee': infoBox['Referee']?['text'] ?? '',
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

  Future<void> _pollLiveDetails(
    List> matches,
    void Function() onUiRefresh,
  ) async {
    final liveMatches = matches
        .where((m) => ['LIVE', '1H', '2H', 'HT'].contains(m['status']))
        .take(15)
        .toList();

    if (liveMatches.isEmpty) return;

    for (final m in liveMatches) {
      await fetchSingleMatchDetails(m);
    }
    onUiRefresh();
  }

  void stop() {
    _secondTimer?.cancel();
    _livePollTimer?.cancel();
  }
}
