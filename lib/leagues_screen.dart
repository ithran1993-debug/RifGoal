import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'league_detail_screen.dart';
import 'football_translations.dart';

class LeaguesScreen extends StatefulWidget {
const LeaguesScreen({super.key});

@override
State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
final TextEditingController searchController = TextEditingController();

List<Map<String, dynamic>> leagues = [];

bool isLoading = true;
String? errorMessage;

@override
void initState() {
super.initState();
fetchLeagues();
}

Future<void> fetchLeagues() async {
if (mounted) {
setState(() {
isLoading = true;
errorMessage = null;
});
}

try {
  final uri = Uri.parse(
    '${ApiConfig.baseUrl}/api/competitions',
  );

  final response = await http.get(
    uri,
    headers: {
      'Accept': 'application/json',
    },
  ).timeout(ApiConfig.timeout);

  if (response.statusCode != 200) {
    throw Exception('خطأ في السيرفر (${response.statusCode})');
  }

  final decoded = jsonDecode(
    utf8.decode(response.bodyBytes),
  );

  if (decoded is! Map<String, dynamic>) {
    throw Exception('بيانات البطولات غير صحيحة');
  }

  if (decoded['success'] == false) {
    throw Exception(
      decoded['error'] ?? 'تعذر جلب البطولات',
    );
  }

  final data = decoded['response'];

  if (data is! List) {
    throw Exception('السيرفر لم يُرجع قائمة البطولات');
  }

  final loadedLeagues = data
      .whereType<Map>()
      .map((item) {
        final league = Map<String, dynamic>.from(item);

        return {
          'id': league['id']?.toString() ?? '',
          'name': league['name']?.toString() ?? '',
          'country': _translateCountry(
            league['country']?.toString() ?? '',
          ),
          'logo': league['logo']?.toString() ?? '',
          'code': league['code']?.toString() ?? '',
        };
      })
      .where((league) =>
          league['id']!.isNotEmpty &&
          league['name']!.isNotEmpty)
      .toList();

  if (!mounted) return;

  setState(() {
    leagues = loadedLeagues;
    isLoading = false;
  });
} catch (error) {
  if (!mounted) return;

  setState(() {
    isLoading = false;
    errorMessage = error.toString().replaceFirst(
      'Exception: ',
      '',
    );
  });
}

}

String _translateCountry(String country) {
const countries = {
'England': 'إنجلترا',
'Spain': 'إسبانيا',
'Italy': 'إيطاليا',
'Germany': 'ألمانيا',
'France': 'فرنسا',
'Europe': 'أوروبا',
};

return countries[country] ?? country;

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
            'البطولات المتاحة',
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
      child: isLoading && leagues.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null && leagues.isEmpty
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: fetchLeagues,
                  child: items.isEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 100),
                            Center(
                              child: Text(
                                'لا توجد بطولة مطابقة للبحث',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            12,
                            5,
                            12,
                            20,
                          ),
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
    ),
  ],
);

}

Widget _buildError() {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.cloud_off,
size: 45,
color: Colors.grey,
),
const SizedBox(height: 12),
Text(
errorMessage ?? 'تعذر جلب البطولات',
textAlign: TextAlign.center,
),
const SizedBox(height: 15),
ElevatedButton.icon(
onPressed: fetchLeagues,
icon: const Icon(Icons.refresh),
label: const Text('إعادة المحاولة'),
),
],
),
),
);
}

Widget _buildLeagueCard(
Map<String, dynamic> league,
int index,
bool isDark,
) {
final logo = league['logo'].toString();

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
          SizedBox(
            width: 27,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
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
            child: logo.isEmpty
                ? const Icon(
                    Icons.emoji_events_outlined,
                    size: 32,
                  )
                : Image.network(
                    logo,
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
