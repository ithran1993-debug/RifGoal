import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';

class MatchService {
  static const String _apiKey = 'eed3b9bde17f4f1694c0796bf739bbb7';
  static const String _baseUrl = 'https://api.football-data.org/v4';

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
        date: now,
      ),
      Match(
        id: '2',
        league: 'cl',
        leagueName: 'دوري أبطال أوروبا',
        home: Team(name: 'ريال مدريد', logo: 'https://media.api-sports.io/football/teams/541.png'),
        away: Team(name: 'مانشستر سيتي', logo: 'https://media.api-sports.io/football/teams/50.png'),
        score: '0 - 0',
        status: 'شوط',
        statusClass: 'half',
        stadium: 'سانتياغو برنابيو',
        referee: 'دافيد كوت',
        round: 'دور الـ 16',
        date: now,
      ),
      Match(
        id: '3',
        league: 'pl',
        leagueName: 'الدوري الإنجليزي',
        home: Team(name: 'ليفربول', logo: 'https://media.api-sports.io/football/teams/40.png'),
        away: Team(name: 'آرسنال', logo: 'https://media.api-sports.io/football/teams/42.png'),
        score: 'vs',
        status: '20:00',
        statusClass: 'upcoming',
        stadium: 'أنفيلد',
        referee: 'أنطوني تايلور',
        round: 'الجولة 10',
        date: now.add(const Duration(days: 1)),
      ),
      Match(
        id: '4',
        league: 'botola',
        leagueName: 'البطولة المغربية',
        home: Team(name: 'الوداد', logo: 'https://media.api-sports.io/football/teams/968.png'),
        away: Team(name: 'الرجاء', logo: 'https://media.api-sports.io/football/teams/967.png'),
        score: '1 - 1',
        status: 'انتهى',
        statusClass: 'finished',
        stadium: 'مركب محمد الخامس',
        referee: 'رضا الجعيدان',
        round: 'الجولة 8',
        date: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static Future<List<Match>> getMatches() async {
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final to = now.add(const Duration(days: 5)).toIso8601String().substring(0, 10);

      final response = await http.get(
        Uri.parse('$_baseUrl/matches?dateFrom=$from&dateTo=$to'),
        headers: {
          'X-Auth-Token': _apiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return _fallbackMatches();
      }

      final data = json.decode(response.body);
      final List list = data['matches'] ?? [];

      if (list.isEmpty) {
        return _fallbackMatches();
      }

      final List<Match> result = [];

      for (final m in list) {
        try {
          final home = m['homeTeam'] ?? {};
          final away = m['awayTeam'] ?? {};
          final fullTime = m['score']?['fullTime'] ?? {};
          final status = (m['status'] ?? 'SCHEDULED').toString();
          final competition = m['competition'] ?? {};

          DateTime? matchDate;
          if (m['utcDate'] != null) {
            matchDate = DateTime.tryParse(m['utcDate'].toString())?.toLocal();
          }

          String scoreText = 'vs';
          if (fullTime['home'] != null && fullTime['away'] != null) {
            scoreText = '${fullTime['home']} - ${fullTime['away']}';
          }

          String statusClass = 'upcoming';
          String statusText = 'قادمة';

          if (status == 'IN_PLAY' || status == 'LIVE') {
            statusClass = 'live';
            statusText = 'مباشر';
          } else if (status == 'PAUSED') {
            statusClass = 'half';
            statusText = 'شوط';
          } else if (status == 'FINISHED') {
            statusClass = 'finished';
            statusText = 'انتهى';
          } else if (matchDate != null) {
            final h = matchDate.hour.toString().padLeft(2, '0');
            final min = matchDate.minute.toString().padLeft(2, '0');
            statusText = '$h:$min';
          }

          result.add(Match(
            id: m['id'].toString(),
            league: (competition['code'] ?? 'unknown').toString().toLowerCase(),
            leagueName: (competition['name'] ?? 'دوري').toString(),
            home: Team(
              name: (home['shortName'] ?? home['name'] ?? 'فريق').toString(),
              logo: (home['crest'] ?? '').toString(),
            ),
            away: Team(
              name: (away['shortName'] ?? away['name'] ?? 'فريق').toString(),
              logo: (away['crest'] ?? '').toString(),
            ),
            score: scoreText,
            status: statusText,
            statusClass: statusClass,
            minute: null,
            stadium: (m['venue'] ?? 'غير محدد').toString(),
            referee: 'غير محدد',
            round: m['matchday'] != null ? 'الجولة ${m['matchday']}' : '',
            events: const [],
            date: matchDate ?? now,
          ));
        } catch (_) {
          // نتجاهل أي مباراة فيها خطأ ونكمل
        }
      }

      if (result.isEmpty) {
        return _fallbackMatches();
      }

      return result;
    } catch (e) {
      return _fallbackMatches();
    }
  }

  static Future<List<Match>> getByLeague(String league) async {
    final matches = await getMatches();
    if (league == 'all') return matches;
    return matches.where((m) => m.league == league).toList();
  }
}
