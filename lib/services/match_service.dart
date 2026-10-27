import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';

class MatchService {
  static const String _apiKey = 'eed3b9bde17f4f1694c0796bf739bbb7';
  static const String _baseUrl = 'https://api.football-data.org/v4';

  // تحويل حالة المباراة من الـ API إلى حالتنا
  static String _mapStatus(String status) {
    switch (status) {
      case 'IN_PLAY':
      case 'LIVE':
        return 'live';
      case 'PAUSED':
        return 'half';
      case 'FINISHED':
        return 'finished';
      default:
        return 'upcoming';
    }
  }

  static String _mapStatusText(String status, Map? score, String? minute) {
    switch (status) {
      case 'IN_PLAY':
      case 'LIVE':
        return minute != null ? "$minute'" : 'مباشر';
      case 'PAUSED':
        return 'شوط';
      case 'FINISHED':
        return 'انتهى';
      case 'SCHEDULED':
      case 'TIMED':
        return 'قادمة';
      default:
        return status;
    }
  }

  static Future<List<Match>> getMatches() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/matches'),
        headers: {
          'X-Auth-Token': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List matchesJson = data['matches'] ?? [];

        return matchesJson.map((m) {
          final home = m['homeTeam'] ?? {};
          final away = m['awayTeam'] ?? {};
          final score = m['score']?['fullTime'] ?? {};
          final status = m['status'] ?? 'SCHEDULED';
          final competition = m['competition'] ?? {};

          String scoreText = 'vs';
          if (score['home'] != null && score['away'] != null) {
            scoreText = '${score['home']} - ${score['away']}';
          }

          return Match(
            id: m['id'].toString(),
            league: competition['code']?.toString().toLowerCase() ?? 'unknown',
            leagueName: competition['name'] ?? 'دوري',
            home: Team(
              name: home['shortName'] ?? home['name'] ?? 'فريق',
              logo: home['crest'] ?? '',
            ),
            away: Team(
              name: away['shortName'] ?? away['name'] ?? 'فريق',
              logo: away['crest'] ?? '',
            ),
            score: scoreText,
            status: _mapStatusText(status, score, null),
            statusClass: _mapStatus(status),
            minute: null,
            stadium: m['venue'] ?? 'غير محدد',
            referee: m['referees'] != null && (m['referees'] as List).isNotEmpty
                ? m['referees'][0]['name'] ?? 'غير محدد'
                : 'غير محدد',
            round: m['matchday'] != null ? 'الجولة ${m['matchday']}' : '',
            events: [],
          );
        }).toList();
      } else {
        print('خطأ في الـ API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('حدث خطأ: $e');
      return [];
    }
  }

  static Future<List<Match>> getByLeague(String league) async {
    final matches = await getMatches();
    if (league == 'all') return matches;
    return matches.where((m) => m.league == league).toList();
  }
}
