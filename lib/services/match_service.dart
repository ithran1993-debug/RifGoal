import '../models/match_model.dart';

class MatchService {
  static List<Match> getMatches() {
    return [
      Match(
        id: 'psv-porto',
        league: 'ucl',
        leagueName: 'أبطال أوروبا',
        home: Team(name: 'آيندهوفن', logo: 'https://media.api-sports.io/football/teams/197.png'),
        away: Team(name: 'بورتو', logo: 'https://media.api-sports.io/football/teams/212.png'),
        score: '0 - 0',
        status: "49'",
        statusClass: 'live',
        minute: '49',
        stadium: 'فيليبس ستاديوم',
        referee: 'كليمان توربان',
        round: 'مرحلة الدوري - الجولة 3',
      ),
      Match(
        id: 'barca-psg',
        league: 'ucl',
        leagueName: 'أبطال أوروبا',
        home: Team(name: 'برشلونة', logo: 'https://media.api-sports.io/football/teams/529.png'),
        away: Team(name: 'باريس سان جيرمان', logo: 'https://media.api-sports.io/football/teams/85.png'),
        score: '0 - 1',
        status: 'شوط',
        statusClass: 'half',
        stadium: 'كامب نو',
        referee: 'مايكل أوليفر',
        round: 'مرحلة الدوري - الجولة 3',
      ),
      Match(
        id: 'manutd-leeds',
        league: 'epl',
        leagueName: 'الدوري الإنجليزي',
        home: Team(name: 'مانشستر يونايتد', logo: 'https://media.api-sports.io/football/teams/33.png'),
        away: Team(name: 'ليدز يونايتد', logo: 'https://media.api-sports.io/football/teams/63.png'),
        score: 'vs',
        status: '01:00 مساءً',
        statusClass: 'upcoming',
        stadium: 'أولد ترافورد',
        referee: 'سيتم تحديده',
        round: 'الجولة 9',
      ),
      Match(
        id: 'wydad-raja',
        league: 'botola',
        leagueName: 'البطولة المغربية',
        home: Team(name: 'الوداد', logo: 'https://media.api-sports.io/football/teams/968.png'),
        away: Team(name: 'الرجاء', logo: 'https://media.api-sports.io/football/teams/967.png'),
        score: '1 - 1',
        status: 'انتهى',
        statusClass: 'finished',
        stadium: 'مركب محمد الخامس',
        referee: 'رضا الجعيدان',
        round: 'الجولة 7',
      ),
    ];
  }

  static List<Match> getByLeague(String league) {
    if (league == 'all') return getMatches();
    return getMatches().where((m) => m.league == league).toList();
  }
}
