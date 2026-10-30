import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_model.dart';

class FavoritesService {
  static final FavoritesService instance = FavoritesService._();
  FavoritesService._();

  static const String _key = 'favorite_matches';
  final List<Match> _favorites = [];

  List<Match> get favorites => List.unmodifiable(_favorites);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _favorites.clear();
    for (final item in raw) {
      try {
        final map = json.decode(item) as Map<String, dynamic>;
        _favorites.add(_fromMap(map));
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _favorites.map((m) => json.encode(_toMap(m))).toList();
    await prefs.setStringList(_key, raw);
  }

  bool isFavorite(String id) {
    return _favorites.any((m) => m.id == id);
  }

  Future<void> toggle(Match match) async {
    if (isFavorite(match.id)) {
      _favorites.removeWhere((m) => m.id == match.id);
    } else {
      _favorites.add(match);
    }
    await _save();
  }

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

  Match _fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'] ?? '',
      league: map['league'] ?? '',
      leagueName: map['leagueName'] ?? '',
      home: Team(name: map['homeName'] ?? '', logo: map['homeLogo'] ?? ''),
      away: Team(name: map['awayName'] ?? '', logo: map['awayLogo'] ?? ''),
      score: map['score'] ?? 'vs',
      status: map['status'] ?? '',
      statusClass: map['statusClass'] ?? 'upcoming',
      minute: map['minute'],
      stadium: map['stadium'] ?? '',
      referee: map['referee'] ?? '',
      round: map['round'] ?? '',
      date: map['date'] != null ? DateTime.tryParse(map['date']) : null,
    );
  }
}
