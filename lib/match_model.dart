class FootballMatch {
  final int id;
  final int? homeTeamId;
  final int? awayTeamId;

  final String leagueName;
  final String leagueCountry;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;

  final int? homeScore;
  final int? awayScore;

  final String date;
  final String status;
  final String statusLong;
  final int? elapsed;

  final String? stadium;
  final String? referee;

  const FootballMatch({
    required this.id,
    this.homeTeamId,
    this.awayTeamId,
    required this.leagueName,
    required this.leagueCountry,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.homeScore,
    required this.awayScore,
    required this.date,
    required this.status,
    required this.statusLong,
    required this.elapsed,
    required this.stadium,
    required this.referee,
  });

  factory FootballMatch.fromApiSports(Map<String, dynamic> json) {
    final fixture = json['fixture'] is Map
        ? Map<String, dynamic>.from(json['fixture'])
        : <String, dynamic>{};

    final league = json['league'] is Map
        ? Map<String, dynamic>.from(json['league'])
        : <String, dynamic>{};

    final teams = json['teams'] is Map
        ? Map<String, dynamic>.from(json['teams'])
        : <String, dynamic>{};

    final home = teams['home'] is Map
        ? Map<String, dynamic>.from(teams['home'])
        : <String, dynamic>{};

    final away = teams['away'] is Map
        ? Map<String, dynamic>.from(teams['away'])
        : <String, dynamic>{};

    final goals = json['goals'] is Map
        ? Map<String, dynamic>.from(json['goals'])
        : <String, dynamic>{};

    final venue = fixture['venue'] is Map
        ? Map<String, dynamic>.from(fixture['venue'])
        : <String, dynamic>{};

    final statusInfo = fixture['status'] is Map
        ? Map<String, dynamic>.from(fixture['status'])
        : <String, dynamic>{};

    return FootballMatch(
      id: _toInt(fixture['id']) ?? 0,

      homeTeamId: _toInt(home['id']),
      awayTeamId: _toInt(away['id']),

      leagueName: _toString(league['name']),
      leagueCountry: _toString(league['country']),

      homeTeam: _toString(home['name']),
      awayTeam: _toString(away['name']),

      homeLogo: _toString(home['logo']),
      awayLogo: _toString(away['logo']),

      homeScore: _toInt(goals['home']),
      awayScore: _toInt(goals['away']),

      date: _toString(fixture['date']),
      status: _toString(statusInfo['short']),
      statusLong: _toString(statusInfo['long']),
      elapsed: _toInt(statusInfo['elapsed']),

      stadium: _nullableString(venue['name']),
      referee: _nullableString(fixture['referee']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  static String? _nullableString(dynamic value) {
    final result = value?.toString().trim();

    if (result == null || result.isEmpty) {
      return null;
    }

    return result;
  }

  bool get isLive {
    return ['1H', '2H', 'HT', 'ET', 'P', 'LIVE'].contains(status);
  }

  bool get isFinished {
    return ['FT', 'AET', 'PEN'].contains(status);
  }
}
