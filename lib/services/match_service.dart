import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';
import '../utils/app_constants.dart';

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
        home: Team(name: 'برشلونة', logo: 'https://crests.football-data.org/81.png'),
        away: Team(name: 'بايرن ميونخ', logo: 'https://crests.football-data.org/5.png'),
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
        home: Team(name: 'ريال مدريد', logo: 'https://crests.football-data.org/86.png'),
        away: Team(name: 'مانشستر سيتي', logo: 'https://crests.football-data.org/65.png'),
        score: '0 - 0',
        status: 'شوط',
        statusClass: 'half',
        stadium: 'سانتياغو برنابيو',
        referee: 'دافيد كوت',
        round: 'دور الـ 16',
        date: now,
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
        headers: {'X-Auth-Token': _apiKey},
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
          String? currentMin;

          if (status == 'IN_PLAY' || status == 'LIVE') {
            statusClass = 'live';
            currentMin = (m['minute'] ?? 35).toString();
            statusText = "'$currentMin";
          } else if (status == 'PAUSED') {
            statusClass = 'half';
            statusText = 'استراحة';
          } else if (status == 'FINISHED') {
            statusClass = 'finished';
            statusText = 'انتهى';
          } else if (matchDate != null) {
            final h = matchDate.hour.toString().padLeft(2, '0');
            final min = matchDate.minute.toString().padLeft(2, '0');
            statusText = '$h:$min';
          }

          final homeRaw = (home['shortName'] ?? home['name'] ?? 'فريق').toString();
          final awayRaw = (away['shortName'] ?? away['name'] ?? 'فريق').toString();

          result.add(Match(
            id: m['id'].toString(),
            league: (competition['code'] ?? 'unknown').toString().toLowerCase(),
            leagueName: AppConstants.translateLeague(competition['name']),
            home: Team(
              name: AppConstants.translateTeam(homeRaw),
              logo: (home['crest'] ?? '').toString(),
            ),
            away: Team(
              name: AppConstants.translateTeam(awayRaw),
              logo: (away['crest'] ?? '').toString(),
            ),
            score: scoreText,
            status: statusText,
            statusClass: statusClass,
            minute: currentMin,
            stadium: (m['venue'] ?? 'غير محدد').toString(),
            referee: 'غير محدد',
            round: m['matchday'] != null ? 'الجولة ${m['matchday']}' : '',
            events: const [],
            date: matchDate ?? now,
          ));
        } catch (_) {}
      }

      return result.isEmpty ? _fallbackMatches() : result;
    } catch (e) {
      return _fallbackMatches();
    }
  }

  static Future<List<Match>> getByLeague(String league) async {
    final matches = await getMatches();
    if (league.toLowerCase() == 'all') return matches;
    return matches.where((m) => m.league.toLowerCase() == league.toLowerCase()).toList();
  }

  static Future<List<Match>> getByTeam(String teamName) async {
    final matches = await getMatches();
    return matches.where((m) =>
      m.home.name.contains(teamName) ||
      m.away.name.contains(teamName) ||
      teamName.contains(m.home.name) ||
      teamName.contains(m.away.name)
    ).toList();
  }

  static Future<List<dynamic>> getStandings(String leagueCode) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/competitions/$leagueCode/standings'),
        headers: {'X-Auth-Token': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final standings = data['standings'] as List? ?? [];
        if (standings.isNotEmpty) {
          return standings[0]['table'] ?? [];
        }
      }
    } catch (_) {}
    return [];
  }
}
