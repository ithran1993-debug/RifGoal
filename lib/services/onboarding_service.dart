import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static final OnboardingService instance = OnboardingService._();
  OnboardingService._();

  static const String _doneKey = 'onboarding_done';
  static const String _leaguesKey = 'fav_leagues';
  static const String _teamsKey = 'fav_teams';

  Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_doneKey) ?? false;
  }

  Future<void> setDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneKey, true);
  }

  Future<void> saveLeagues(List<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_leaguesKey, codes);
  }

  Future<List<String>> getLeagues() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_leaguesKey) ?? [];
  }

  Future<void> saveTeams(List<String> teams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_teamsKey, teams);
  }

  Future<List<String>> getTeams() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_teamsKey) ?? [];
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_doneKey);
    await prefs.remove(_leaguesKey);
    await prefs.remove(_teamsKey);
  }
}
