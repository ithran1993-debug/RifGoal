import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'favorites_service.dart';
import 'football_translations.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onFinished;

  const OnboardingScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final FavoritesService favoritesService = FavoritesService();

  static const String _doneKey = 'rifgoal_onboarding_done';

  final List<Map<String, dynamic>> availableLeagues = [
    {'id': 2, 'name': 'UEFA Champions League', 'logo': ''},
    {'id': 39, 'name': 'Premier League', 'logo': ''},
    {'id': 140, 'name': 'La Liga', 'logo': ''},
    {'id': 135, 'name': 'Serie A', 'logo': ''},
    {'id': 78, 'name': 'Bundesliga', 'logo': ''},
    {'id': 61, 'name': 'Ligue 1', 'logo': ''},
    {'id': 200, 'name': 'Botola Pro', 'logo': ''},
  ];

  final Set<int> selectedLeagueIds = {};
  final Set<String> selectedTeamIds = {};

  final Map<int, List<Map<String, dynamic>>> teamsByLeague = {};

  int? activeLeagueId;
  bool isLoadingTeams = false;
  bool isSaving = false;
  String? errorMessage;

  int get currentSeason {
    final now = DateTime.now();
    return now.month >= 7 ? now.year : now.year - 1;
  }

  Future<void> _loadTeams(int leagueId) async {
    if (teamsByLeague.containsKey(leagueId)) {
      return;
    }

    setState(() {
      isLoadingTeams = true;
      errorMessage = null;
      activeLeagueId = leagueId;
    });

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/teams',
      ).replace(
        queryParameters: {
          'league': leagueId.toString(),
          'season': currentSeason.toString(),
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'تعذر تحميل الفرق: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is! Map || decoded['response'] is! List) {
        throw Exception('صيغة بيانات الفرق غير صحيحة.');
      }

      final List<Map<String, dynamic>> loadedTeams = [];

      for (final item in decoded['response']) {
        if (item is! Map) continue;

        final team = item['team'] is Map
            ? Map<String, dynamic>.from(item['team'])
            : Map<String, dynamic>.from(item);

        final id = team['id'];
        if (id == null) continue;

        loadedTeams.add({
          'id': id.toString(),
          'name': team['name']?.toString() ?? 'فريق',
          'logo': team['logo']?.toString() ?? '',
        });
      }

      if (!mounted) return;

      setState(() {
        teamsByLeague[leagueId] = loadedTeams;
        isLoadingTeams = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            error.toString().replaceFirst('Exception: ', '');
        isLoadingTeams = false;
      });
    }
  }

  Future<void> _toggleLeague(
    Map<String, dynamic> league,
  ) async {
    final id = league['id'] as int;

    if (selectedLeagueIds.contains(id)) {
      setState(() {
        selectedLeagueIds.remove(id);

        if (activeLeagueId == id) {
          activeLeagueId = null;
        }
      });
      return;
    }

    setState(() {
      selectedLeagueIds.add(id);
      activeLeagueId = id;
    });

    await _loadTeams(id);
  }

  void _toggleTeam(String teamId) {
    setState(() {
      if (selectedTeamIds.contains(teamId)) {
        selectedTeamIds.remove(teamId);
      } else {
        selectedTeamIds.add(teamId);
      }
    });
  }

  Future<void> _saveSelections() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      for (final leagueId in selectedLeagueIds) {
        final league = availableLeagues.firstWhere(
          (item) => item['id'] == leagueId,
        );

        await favoritesService.saveLeague(
          id: leagueId.toString(),
          name: FootballTranslations.league(
            league['name'].toString(),
          ),
          logo: league['logo'].toString(),
        );
      }

      for (final entry in teamsByLeague.entries) {
        for (final team in entry.value) {
          final id = team['id'].toString();

          if (!selectedTeamIds.contains(id)) continue;

          await favoritesService.saveTeam(
            id: id,
            name: FootballTranslations.team(
              team['name'].toString(),
            ),
            logo: team['logo'].toString(),
          );
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_doneKey, true);

      if (!mounted) return;

      await widget.onFinished();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'تعذر حفظ الاختيارات. حاول مرة أخرى.';
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'مرحباً بك في Rif Goal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: 48,
                    color: primary,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'اختر البطولات والفرق التي تتابعها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ستجد اختياراتك محفوظة في قسم المفضلة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '1. اختر البطولات',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 112,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: availableLeagues.length,
                itemBuilder: (context, index) {
                  final league = availableLeagues[index];
                  final id = league['id'] as int;
                  final selected = selectedLeagueIds.contains(id);

                  return GestureDetector(
                    onTap: () => _toggleLeague(league),
                    child: Container(
                      width: 125,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: selected
                            ? primary.withOpacity(0.12)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: selected
                              ? primary
                              : Theme.of(context).dividerColor,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected
                                ? Icons.star
                                : Icons.emoji_events_outlined,
                            color: selected ? Colors.amber : primary,
                            size: 27,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            FootballTranslations.league(
                              league['name'].toString(),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '2. اختر الفرق',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${selectedTeamIds.length} فريق',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildTeamsContent(),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveSelections,
                  child: isSaving
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'حفظ الاختيارات والبدء',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsContent() {
    if (selectedLeagueIds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'اختر بطولة من الأعلى لعرض الفرق المشاركة فيها.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (activeLeagueId == null) {
      return const Center(
        child: Text('اختر بطولة لعرض فرقها.'),
      );
    }

    if (isLoadingTeams) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          textAlign: TextAlign.center,
        ),
      );
    }

    final teams = teamsByLeague[activeLeagueId] ?? [];

    if (teams.isEmpty) {
      return const Center(
        child: Text('لا توجد فرق متاحة لهذه البطولة.'),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: availableLeagues
                .where(
                  (league) => selectedLeagueIds.contains(league['id']),
                )
                .map((league) {
              final id = league['id'] as int;
              final active = activeLeagueId == id;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    FootballTranslations.league(
                      league['name'].toString(),
                    ),
                  ),
                  selected: active,
                  onSelected: (_) async {
                    setState(() {
                      activeLeagueId = id;
                    });
                    await _loadTeams(id);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final id = team['id'].toString();
              final selected = selectedTeamIds.contains(id);

              return CheckboxListTile(
                value: selected,
                onChanged: (_) => _toggleTeam(id),
                secondary: SizedBox(
                  width: 38,
                  height: 38,
                  child: team['logo'].toString().isEmpty
                      ? const Icon(Icons.shield_outlined)
                      : Image.network(
                          team['logo'].toString(),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const Icon(Icons.shield_outlined);
                          },
                        ),
                ),
                title: Text(
                  FootballTranslations.team(
                    team['name'].toString(),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ),
      ],
    );
  }
}
