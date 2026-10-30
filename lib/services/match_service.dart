import '../models/match_model.dart';

class MatchService {
  static Future<List<Match>> getMatches() async {
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
        league: 'pl',
        leagueName: 'الدوري الإنجليزي',
        home: Team(name: 'تشيلسي', logo: 'https://media.api-sports.io/football/teams/49.png'),
        away: Team(name: 'توتنهام', logo: 'https://media.api-sports.io/football/teams/47.png'),
        score: 'vs',
        status: '17:30',
        statusClass: 'upcoming',
        stadium: 'ستامفورد بريدج',
        referee: 'بول تيرنر',
        round: 'الجولة 10',
        date: now.add(const Duration(days: 1)),
      ),
      Match(
        id: '5',
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

  static Future<List<Match>> getByLeague(String league) async {
    final matches = await getMatches();
    if (league == 'all') return matches;
    return matches.where((m) => m.league == league).toList();
  }
}
