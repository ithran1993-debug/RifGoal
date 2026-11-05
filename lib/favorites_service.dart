import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _teamsKey = 'rifgoal_favorite_teams';
  static const String _leaguesKey = 'rifgoal_favorite_leagues';

  static const String _teamDetailsKey = 'rifgoal_favorite_team_details';
  static const String _leagueDetailsKey = 'rifgoal_favorite_league_details';

  // جلب معرّفات الفرق المفضلة
  Future<List<String>> getFavoriteTeams() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_teamsKey) ?? [];
  }

  // جلب معرّفات البطولات المفضلة
  Future<List<String>> getFavoriteLeagues() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_leaguesKey) ?? [];
  }

  // إضافة فريق بالطريقة القديمة
  Future<void> addTeam(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final teams = prefs.getStringList(_teamsKey) ?? [];

    if (!teams.contains(teamId)) {
      teams.add(teamId);
      await prefs.setStringList(_teamsKey, teams);
    }
  }

  // حذف فريق
  Future<void> removeTeam(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final teams = prefs.getStringList(_teamsKey) ?? [];

    teams.remove(teamId);
    await prefs.setStringList(_teamsKey, teams);

    final details = await getFavoriteTeamDetails();
    details.removeWhere((item) => item['id'] == teamId);
    await _saveDetails(_teamDetailsKey, details);
  }

  // إضافة بطولة بالطريقة القديمة
  Future<void> addLeague(String leagueId) async {
    final prefs = await SharedPreferences.getInstance();
    final leagues = prefs.getStringList(_leaguesKey) ?? [];

    if (!leagues.contains(leagueId)) {
      leagues.add(leagueId);
      await prefs.setStringList(_leaguesKey, leagues);
    }
  }

  // حذف بطولة
  Future<void> removeLeague(String leagueId) async {
    final prefs = await SharedPreferences.getInstance();
    final leagues = prefs.getStringList(_leaguesKey) ?? [];

    leagues.remove(leagueId);
    await prefs.setStringList(_leaguesKey, leagues);

    final details = await getFavoriteLeagueDetails();
    details.removeWhere((item) => item['id'] == leagueId);
    await _saveDetails(_leagueDetailsKey, details);
  }

  // حفظ فريق مع اسمه وشعاره
  Future<void> saveTeam({
    required String id,
    required String name,
    String logo = '',
  }) async {
    await addTeam(id);

    final details = await getFavoriteTeamDetails();

    details.removeWhere((item) => item['id'] == id);

    details.add({
      'id': id,
      'name': name,
      'logo': logo,
    });

    await _saveDetails(_teamDetailsKey, details);
  }

  // حفظ بطولة مع اسمها وشعارها
  Future<void> saveLeague({
    required String id,
    required String name,
    String logo = '',
  }) async {
    await addLeague(id);

    final details = await getFavoriteLeagueDetails();

    details.removeWhere((item) => item['id'] == id);

    details.add({
      'id': id,
      'name': name,
      'logo': logo,
    });

    await _saveDetails(_leagueDetailsKey, details);
  }

  // جلب تفاصيل الفرق المفضلة
  Future<List<Map<String, dynamic>>> getFavoriteTeamDetails() async {
    return _getDetails(_teamDetailsKey);
  }

  // جلب تفاصيل البطولات المفضلة
  Future<List<Map<String, dynamic>>> getFavoriteLeagueDetails() async {
    return _getDetails(_leagueDetailsKey);
  }

  // قراءة التفاصيل المحفوظة
  Future<List<Map<String, dynamic>>> _getDetails(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(key);

    if (savedData == null) return [];

    try {
      final decoded = jsonDecode(savedData);

      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // حفظ التفاصيل
  Future<void> _saveDetails(
    String key,
    List<Map<String, dynamic>> details,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(details));
  }
}
