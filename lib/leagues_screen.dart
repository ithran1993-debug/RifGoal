import 'package:flutter/material.dart';

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

  Set<String> favoriteLeagueIds = {};

  // قائمة البطولات المحلية المرتبة حسب القوة والشهرة
  final List<Map<String, dynamic>> leagues = [
    {
      'id': '2',
      'name': 'UEFA Champions League',
      'country': 'أوروبا',
      'logo': 'https://media.api-sports.io/football/leagues/2.png',
    },
    {
      'id': '39',
      'name': 'Premier League',
      'country': 'إنجلترا',
      'logo': 'https://media.api-sports.io/football/leagues/39.png',
    },
    {
      'id': '140',
      'name': 'La Liga',
      'country': 'إسبانيا',
      'logo': 'https://media.api-sports.io/football/leagues/140.png',
    },
    {
      'id': '135',
      'name': 'Serie A',
      'country': 'إيطاليا',
      'logo': 'https://media.api-sports.io/football/leagues/135.png',
    },
    {
      'id': '78',
      'name': 'Bundesliga',
      'country': 'ألمانيا',
      'logo': 'https://media.api-sports.io/football/leagues/78.png',
    },
    {
      'id': '61',
      'name': 'Ligue 1',
      'country': 'فرنسا',
      'logo': 'https://media.api-sports.io/football/leagues/61.png',
    },
    {
      'id': '12',
      'name': 'CAF Champions League',
      'country': 'إفريقيا',
      'logo': 'https://media.api-sports.io/football/leagues/12.png',
    },
    {
      'id': '307',
      'name': 'Saudi Pro League',
      'country': 'السعودية',
      'logo': 'https://media.api-sports.io/football/leagues/307.png',
    },
    {
      'id': '94',
      'name': 'Primeira Liga',
      'country': 'البرتغال',
      'logo': 'https://media.api-sports.io/football/leagues/94.png',
    },
    {
      'id': '88',
      'name': 'Eredivisie',
      'country': 'هولندا',
      'logo': 'https://media.api-sports.io/football/leagues/88.png',
    },
    {
      'id': '71',
      'name': 'Serie A',
      'country': 'البرازيل',
      'logo': 'https://media.api-sports.io/football/leagues/71.png',
    },
    {
      'id': '128',
      'name': 'Liga Profesional',
      'country': 'الأرجنتين',
      'logo': 'https://media.api-sports.io/football/leagues/128.png',
    },
    {
      'id': '203',
      'name': 'Super Lig',
      'country': 'تركيا',
      'logo': 'https://media.api-sports.io/football/leagues/203.png',
    },
    {
      'id': '200',
      'name': 'Botola Pro',
      'country': 'المغرب',
      'logo': 'https://media.api-sports.io/football/leagues/200.png',
    },
    {
      'id': '253',
      'name': 'MLS',
      'country': 'أمريكا',
      'logo': 'https://media.api-sports.io/football/leagues/253.png',
    },
    {
      'id': '233',
      'name': 'Premier League',
      'country': 'مصر',
      'logo': 'https://media.api-sports.io/football/leagues/233.png',
    },
    {
      'id': '144',
      'name': 'Jupiler Pro League',
      'country': 'بلجيكا',
      'logo': 'https://media.api-sports.io/football/leagues/144.png',
    },
    {
      'id': '179',
      'name': 'Premiership',
      'country': 'اسكتلندا',
      'logo': 'https://media.api-sports.io/football/leagues/179.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final favorites = await favoritesService.getFavoriteLeagues();

    if (!mounted) return;

    setState(() {
      favoriteLeagueIds = favorites.toSet();
    });
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
    final primary = Theme.of(context).colorScheme.primary;
    final items = filteredLeagues;

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

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'أهم البطولات العالمية',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} بطولة',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text('لا توجد بطولة مطابقة للبحث'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 5, 12, 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildLeagueCard(
                      items[index],
                      index,
                      isDark,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLeagueCard(
    Map<String, dynamic> league,
    int index,
    bool isDark,
  ) {
    final id = league['id'].toString();
    final isFavorite = favoriteLeagueIds.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => openLeagueDetails(league),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 27,
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              SizedBox(
                width: 45,
                height: 45,
                child: Image.network(
                  league['logo'].toString(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.emoji_events_outlined,
                      size: 32,
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
                      FootballTranslations.league(
                        league['name'].toString(),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      league['country'].toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () => toggleFavorite(league),
                tooltip: 'المفضلة',
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.grey,
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
