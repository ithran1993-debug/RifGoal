  Map<String, dynamic> _toMap(Match m) {
    return {
      'id': m.id,
      'league': m.league,
      'leagueName': m.leagueName,
      'homeName': m.home.name,
      'homeLogo': m.home.logo,
      'awayName': m.away.name,
      'awayLogo': m.away.logo,
      'score': m.score,
      'status': m.status,
      'statusClass': m.statusClass,
      'minute': m.minute,
      'stadium': m.stadium,
      'referee': m.referee,
      'round': m.round,
      'date': m.date?.toIso8601String(),
    };
  }
