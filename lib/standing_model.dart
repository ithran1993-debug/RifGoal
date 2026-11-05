class Standing {
  final int position;
  final String teamName;
  final String teamLogo;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final String description;

  const Standing({
    required this.position,
    required this.teamName,
    required this.teamLogo,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
    required this.description,
  });

  factory Standing.fromApiSports(Map<String, dynamic> json) {
    final team = json['team'] is Map
        ? Map<String, dynamic>.from(json['team'])
        : <String, dynamic>{};

    return Standing(
      position: _number(json['rank']),
      teamName: _string(team['name']),
      teamLogo: _string(team['logo']),
      played: _number(json['all']?['played']),
      won: _number(json['all']?['win']),
      drawn: _number(json['all']?['draw']),
      lost: _number(json['all']?['lose']),
      goalsFor: _number(json['all']?['goals']?['for']),
      goalsAgainst: _number(json['all']?['goals']?['against']),
      points: _number(json['points']),
      description: _string(json['description']),
    );
  }

  static int _number(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _string(dynamic value) {
    return value?.toString() ?? '';
  }

  int get goalDifference => goalsFor - goalsAgainst;
}
