class FootballMatch {
  final int id;
  final int leagueId;

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

  final DateTime date;

  final String status;
  final String statusLong;

  final int? elapsed;

  final String stadium;
  final String referee;
  final String channel;
  final String commentator;

  FootballMatch({
    required this.id,
    this.leagueId = 0,
    this.homeTeamId,
    this.awayTeamId,
    required this.leagueName,
    required this.leagueCountry,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    this.homeScore,
    this.awayScore,
    required this.date,
    required this.status,
    required this.statusLong,
    this.elapsed,
    required this.stadium,
    required this.referee,
    this.channel = '',
    this.commentator = '',
  });

  // قراءة البيانات القادمة من Cloudflare Worker و app_data.json
  factory FootballMatch.fromWorkerJson(Map<String, dynamic> json) {
    final leagueStr = _toString(json['league'] ?? json['leagueName']);
    final rawDate = _toString(json['timestamp'] ?? json['date']);
    final minuteStr = _toString(json['minute']);
    final parsedElapsed = int.tryParse(
      minuteStr.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    return FootballMatch(
      id: _toInt(json['id']),
      leagueId: _mapLeagueId(leagueStr),
      leagueName: leagueStr,
      leagueCountry: '',
      homeTeam: _toString(json['home'] ?? json['homeTeam']),
      awayTeam: _toString(json['away'] ?? json['awayTeam']),
      homeLogo: _toString(json['homeLogo']),
      awayLogo: _toString(json['awayLogo']),
      homeScore: _nullableInt(json['scoreHome'] ?? json['homeScore']),
      awayScore: _nullableInt(json['scoreAway'] ?? json['awayScore']),
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      status: _toString(json['status']).isEmpty
          ? 'NS'
          : _toString(json['status']),
      statusLong: _toString(json['statusLong']),
      elapsed: parsedElapsed ?? _nullableInt(json['elapsed']),
      stadium: _toString(json['stadium']),
      referee: _toString(json['referee']),
      channel: _toString(json['channel']),
      commentator: _toString(json['commentator']),
    );
  }

  factory FootballMatch.fromApiSports(
    Map<String, dynamic> json,
  ) {
    final fixture = json['fixture'] is Map
        ? Map<String, dynamic>.from(json['fixture'])
        : <String, dynamic>{};

    final league = json['league'] is Map
        ? Map<String, dynamic>.from(json['league'])
        : <String, dynamic>{};

    final teams = json['teams'] is Map
        ? Map<String, dynamic>.from(json['teams'])
        : <String, dynamic>{};

    final goals = json['goals'] is Map
        ? Map<String, dynamic>.from(json['goals'])
        : <String, dynamic>{};

    final home = teams['home'] is Map
        ? Map<String, dynamic>.from(teams['home'])
        : <String, dynamic>{};

    final away = teams['away'] is Map
        ? Map<String, dynamic>.from(teams['away'])
        : <String, dynamic>{};

    final venue = fixture['venue'] is Map
        ? Map<String, dynamic>.from(fixture['venue'])
        : <String, dynamic>{};

    final statusData = fixture['status'] is Map
        ? Map<String, dynamic>.from(fixture['status'])
        : <String, dynamic>{};

    return FootballMatch(
      id: _toInt(fixture['id']),
      leagueId: _toInt(league['id']),
      homeTeamId: _nullableInt(home['id']),
      awayTeamId: _nullableInt(away['id']),
      leagueName: _toString(league['name']),
      leagueCountry: _toString(league['country']),
      homeTeam: _toString(home['name']),
      awayTeam: _toString(away['name']),
      homeLogo: _toString(home['logo']),
      awayLogo: _toString(away['logo']),
      homeScore: _nullableInt(goals['home']),
      awayScore: _nullableInt(goals['away']),
      date: DateTime.tryParse(
            _toString(fixture['date']),
          ) ??
          DateTime.now(),
      status: _toString(statusData['short']),
      statusLong: _toString(statusData['long']),
      elapsed: _nullableInt(statusData['elapsed']),
      stadium: _toString(venue['name']),
      referee: _toString(fixture['referee']),
    );
  }

  static int _mapLeagueId(String leagueName) {
    if (leagueName.contains('أبطال أوروبا')) return 2;
    if (leagueName.contains('الإنجليزي')) return 39;
    if (leagueName.contains('الإسباني')) return 140;
    if (leagueName.contains('الإيطالي')) return 135;
    if (leagueName.contains('الألماني')) return 78;
    if (leagueName.contains('الفرنسي')) return 61;
    if (leagueName.contains('المغربي')) return 200;
    return 99;
  }

  bool get isLive {
    return const [
      '1H',
      '2H',
      'HT',
      'ET',
      'P',
      'LIVE',
    ].contains(status);
  }

  bool get isFinished {
    return const [
      'FT',
      'AET',
      'PEN',
    ].contains(status);
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }
}
