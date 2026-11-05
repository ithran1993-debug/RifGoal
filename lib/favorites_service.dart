import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _teamsKey = 'rifgoal_favorite_teams';
  static const String _leaguesKey = 'rifgoal_favorite_leagues';

  Future<List<String>> getFavoriteTeams() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_teamsKey) ?? [];
  }

  Future<List<String>> getFavoriteLeagues() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_leaguesKey) ?? [];
  }

  Future<void> addTeam(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final teams = prefs.getStringList(_teamsKey) ?? [];

    if (!teams.contains(teamId)) {
      teams.add(teamId);
      await prefs.setStringList(_teamsKey, teams);
    }
  }

  Future<void> removeTeam(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final teams = prefs.getStringList(_teamsKey) ?? [];

    teams.remove(teamId);
    await prefs.setStringList(_teamsKey, teams);
  }

  Future<void> addLeague(String leagueId) async {
    final prefs = await SharedPreferences.getInstance();
    final leagues = prefs.getStringList(_leaguesKey) ?? [];

    if (!leagues.contains(leagueId)) {
      leagues.add(leagueId);
      await prefs.setStringList(_leaguesKey, leagues);
    }
  }

  Future<void> removeLeague(String leagueId) async {
    final prefs = await SharedPreferences.getInstance();
    final leagues = prefs.getStringList(_leaguesKey) ?? [];

    leagues.remove(leagueId);
    await prefs.setStringList(_leaguesKey, leagues);
  }
}
