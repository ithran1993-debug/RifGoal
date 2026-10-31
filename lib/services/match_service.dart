import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';
import '../utils/app_constants.dart';

class MatchService {
  static const String _apiKey = '60380bdc41e945a2c17619bdcc6944bf';
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  static Map<String, String> get _headers => {
    'x-apisports-key': _apiKey,
  };

  // قائمة مباريات احتياطية في حال تعثر الاتصال
  static List<Match> _fallbackMatches() {
    final now = DateTime.now();
    return [
      Match(
        id: '1',
        league: 'cl',
        leagueName: 'دوري أبطال أوروبا',
        home: Team(name: 'برشلونة', logo: 'https://media.api-sports.io/football/teams/529.png'),
        away: Team(name: 'بايرن ميونخ', logo: 'https://media.api-sports.io/football/teams/157.png'),
        score: '2 - 1',
        status: "67'",
        statusClass: 'live',
        minute: '67',
        stadium: 'كامب نو',
        referee: 'مايكل أوليفر',
        round: 'دور الـ 16',
        events: const [],
        date: now,
      ),
    ];
  }

  // 1. جلب مباريات اليوم مع تفاصيل الدقائق الحية ودقائق الأهداف
  static Future<List<Match>> getMatches({String? dateStr}) async {
    try {
      final String targetDate = dateStr ?? DateTime.now().toIso8601String().substring(0, 10);
      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures?date=$targetDate'),
        headers: _headers,
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return _fallbackMatches();
      }

      final data = json.decode(response.body);
      final List fixtures = data['response'] ?? [];

      if (fixtures.isEmpty) {
        return _fallbackMatches();
      }

      final List<Match> result = [];

      for (final item in fixtures) {
        try {
          final fixture = item['fixture'] ?? {};
          final league = item['league'] ?? {};
          final teams = item['teams'] ?? {};
          final goals = item['goals'] ?? {};
          final statusInfo = fixture['status'] ?? {};
          final shortStatus = (statusInfo['short'] ?? '').toString().toUpperCase();

          // تحديد الدقيقة المباشرة وحالة المباراة
          final int? elapsed = statusInfo['elapsed'] != null 
              ? int.tryParse(statusInfo['elapsed'].toString()) 
              : null;

          String statusClass = 'upcoming';
          String statusText = 'قادمة';
          String? currentMin;

          if (['1H', '2H', 'ET', 'LIVE'].contains(shortStatus)) {
            statusClass = 'live';
            currentMin = (elapsed ?? 1).toString();
            statusText = "'$currentMin";
          } else if (shortStatus == 'HT') {
            statusClass = 'half';
            statusText = 'استراحة';
            currentMin = '45';
          } else if (['FT', 'AET', 'PEN'].contains(shortStatus)) {
            statusClass = 'finished';
            statusText = 'انتهى';
          } else if (fixture['date'] != null) {
            final dt = DateTime.tryParse(fixture['date'].toString())?.toLocal();
            if (dt != null) {
              final h = dt.hour.toString().padLeft(2, '0');
              final m = dt.minute.toString().padLeft(2, '0');
              statusText = '$h:$m';
            }
          }

          // النتيجة
          String scoreText = 'vs';
          if (goals['home'] != null && goals['away'] != null) {
            scoreText = '${goals['home']} - ${goals['away']}';
          }

          // توقيت وتاريخ اللقاء
          DateTime? matchDate;
          if (fixture['date'] != null) {
            matchDate = DateTime.tryParse(fixture['date'].toString())?.toLocal();
          }

          final homeRaw = (teams['home']?['name'] ?? 'المضيف').toString();
          final awayRaw = (teams['away']?['name'] ?? 'الضيف').toString();

          result.add(Match(
            id: fixture['id'].toString(),
            league: (league['id'] ?? 'league').toString(),
            leagueName: AppConstants.translateLeague((league['name'] ?? '').toString()),
            home: Team(
              name: AppConstants.translateTeam(homeRaw),
              logo: (teams['home']?['logo'] ?? '').toString(),
            ),
            away: Team(
              name: AppConstants.translateTeam(awayRaw),
              logo: (teams['away']?['logo'] ?? '').toString(),
            ),
            score: scoreText,
            status: statusText,
            statusClass: statusClass,
            minute: currentMin,
            stadium: (fixture['venue']?['name'] ?? 'غير محدد').toString(),
            referee: (fixture['referee'] ?? 'غير محدد').toString(),
            round: (league['round'] ?? '').toString(),
            events: const [],
            date: matchDate ?? DateTime.now(),
          ));
        } catch (_) {}
      }

      return result.isEmpty ? _fallbackMatches() : result;
    } catch (e) {
      debugPrint('Error getMatches: $e');
      return _fallbackMatches();
    }
  }

  // 2. دالة جلب دقائق الأهداف الحقيقية لأي مباراة مباشرة
  static Future<List<int>> getRealGoalMinutes(String fixtureId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures/events?fixture=$fixtureId&type=Goal'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List events = data['response'] ?? [];
        final List<int> minutes = [];

        for (var ev in events) {
          final time = ev['time'];
          if (time != null && time['elapsed'] != null) {
            final int? m = int.tryParse(time['elapsed'].toString());
            if (m != null) minutes.add(m);
          }
        }
        return minutes;
      }
    } catch (e) {
      debugPrint('Error getRealGoalMinutes: $e');
    }
    return [];
  }

  // 3. تصفية المباريات بحسب الدوري
  static Future<List<Match>> getByLeague(String leagueId) async {
    final matches = await getMatches();
    if (leagueId.toLowerCase() == 'all') return matches;
    return matches.where((m) => m.league.toLowerCase() == leagueId.toLowerCase()).toList();
  }

  // 4. تصفية المباريات بحسب الفريق
  static Future<List<Match>> getByTeam(String teamName) async {
    final matches = await getMatches();
    return matches.where((m) =>
      m.home.name.contains(teamName) ||
      m.away.name.contains(teamName) ||
      teamName.contains(m.home.name) ||
      teamName.contains(m.away.name)
    ).toList();
  }
}
