class Team {
  final String name;
  final String logo;

  Team({required this.name, required this.logo});
}

class MatchEvent {
  final String minute;
  final String text;

  MatchEvent({required this.minute, required this.text});
}

class Match {
  final String id;
  final String league;
  final String leagueName;
  final Team home;
  final Team away;
  final String score;
  final String status;
  final String statusClass;
  final String? minute;
  final String stadium;
  final String referee;
  final String round;
  final List<MatchEvent> events;
  final DateTime? date; // جديد

  Match({
    required this.id,
    required this.league,
    required this.leagueName,
    required this.home,
    required this.away,
    required this.score,
    required this.status,
    required this.statusClass,
    this.minute,
    required this.stadium,
    required this.referee,
    required this.round,
    this.events = const [],
    this.date,
  });
}
