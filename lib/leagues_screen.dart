import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'favorites_service.dart';
import 'league_detail_screen.dart';
import 'football_translations.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  final FavoritesService favoritesService = FavoritesService();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> leagues = [];
  Set<String> favoriteLeagueIds = {};

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadLeagues();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final favorites = await favoritesService.getFavoriteLeagues();

    if (!mounted) return;

    setState(() {
      favoriteLeagueIds = favorites.toSet();
    });
  }

  Future<void> loadLeagues() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/leagues');

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'تعذر تحميل البطولات. رمز الاستجابة: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map || decoded['response'] is! List) {
        throw Exception('صيغة بيانات البطولات غير صحيحة.');
      }

      final List<Map<String, dynamic>> loadedLeagues = [];

      for (final item in decoded['response']) {
        if (item is! Map) continue;

        final leagueData = item['league'] is Map
            ? Map<String, dynamic>.from(item['league'])
            : <String, dynamic>{};

        final countryData = item['country'] is Map
            ? Map<String, dynamic>.from(item['country'])
            : <String, dynamic>{};

        final id = leagueData['id'];

        if (id == null) continue;

        loadedLeagues.add({
          'id': id.toString(),
          'name': leagueData['name']?.toString() ?? 'بطولة',
          'logo': leagueData['logo']?.toString() ?? '',
          'country': countryData['name']?.toString() ?? '',
          'flag': countryData['flag']?.toString() ?? '',
          'type': leagueData['type']?.toString() ?? '',
        });
      }

      if (!mounted) return;

      setState(() {
        leagues = loadedLeagues;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            error.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> league) async {
    final id = league['id'].toString();
    final isFavorite = favoriteLeagueIds.contains(id);

    if (isFavorite) {
      await favoritesService.removeLeague(id);
    } else {
      await favoritesService.saveLeague(
        id: id,
        name: FootballTranslations.league(
          league['name'].toString(),
        ),
        logo: league['logo'].toString(),
      );
    }

    if (!mounted) return;

    setState(() {
      if (isFavorite) {
        favoriteLeagueIds.remove(id);
      } else {
        favoriteLeagueIds.add(id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? 'تم حذف البطولة من المفضلة'
              : 'تمت إضافة البطولة إلى المفضلة',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void openLeagueDetails(Map<String, dynamic> league) {
    final id = int.tryParse(league['id'].toString());

    if (id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeagueDetailScreen(
          leagueId: id,
          leagueName: league['name'].toString(),
          leagueLogo: league['logo'].toString(),
          country: league['country'].toString(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredLeagues {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return leagues;

    return leagues.where((league) {
      final name = league['name'].toString().toLowerCase();
      final translatedName = FootballTranslations.league(
        league['name'].toString(),
      ).toLowerCase();

      final country = league['country'].toString().toLowerCase();

      return name.contains(query) ||
          translatedName.contains(query) ||
          country.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث عن بطولة أو بلد...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildContent(isDark),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 12),
              const Text(
                'تعذر تحميل البطولات',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: loadLeagues,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final items = filteredLeagues;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadLeagues,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.emoji_events_outlined, size: 55),
            SizedBox(height: 15),
            Center(child: Text('لا توجد بطولات مطابقة')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadLeagues,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildLeagueCard(items[index], isDark);
        },
      ),
    );
  }

  Widget _buildLeagueCard(
    Map<String, dynamic> league,
    bool isDark,
  ) {
    final id = league['id'].toString();
    final isFavorite = favoriteLeagueIds.contains(id);

    final translatedLeagueName = FootballTranslations.league(
      league['name'].toString(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => openLeagueDetails(league),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: league['logo'].toString().isEmpty
                    ? const Icon(
                        Icons.emoji_events_outlined,
                        size: 35,
                      )
                    : Image.network(
                        league['logo'].toString(),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.emoji_events_outlined,
                            size: 35,
                          );
                        },
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translatedLeagueName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      league['country'].toString().isEmpty
                          ? 'بطولة كرة القدم'
                          : league['country'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'اضغط لعرض المباريات والترتيب',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite
                    ? 'حذف من المفضلة'
                    : 'إضافة للمفضلة',
                onPressed: () => toggleFavorite(league),
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.grey,
                  size: 27,
                ),
              ),
              const Icon(
                Icons.chevron_left,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
