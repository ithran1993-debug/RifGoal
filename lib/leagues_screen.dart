import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

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
String searchQuery = '';

@override
void initState() {
super.initState();
loadLeagues();
}

@override
void dispose() {
searchController.dispose();
super.dispose();
}

Future<void> loadLeagues() async {
setState(() {
isLoading = true;
errorMessage = null;
});

try {
  final url = Uri.parse('${ApiConfig.baseUrl}/api/leagues');

  final response = await http
      .get(url, headers: {'Accept': 'application/json'})
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 200) {
    throw Exception('رمز الاستجابة: ${response.statusCode}');
  }

  final decoded = jsonDecode(utf8.decode(response.bodyBytes));

  if (decoded is! Map) {
    throw Exception('صيغة بيانات البطولات غير صحيحة');
  }

  if (decoded['errors'] is Map &&
      (decoded['errors'] as Map).isNotEmpty) {
    throw Exception('السيرفر أعاد خطأ في طلب البطولات');
  }

  final data = decoded['response'];

  if (data is! List) {
    throw Exception('لم يتم العثور على قائمة البطولات');
  }

  final loadedLeagues = <Map<String, dynamic>>[];

  for (final item in data) {
    if (item is! Map) continue;

    final league = item['league'] is Map
        ? Map<String, dynamic>.from(item['league'])
        : <String, dynamic>{};

    final country = item['country'] is Map
        ? Map<String, dynamic>.from(item['country'])
        : <String, dynamic>{};

    if (league.isEmpty) continue;

    loadedLeagues.add({
      'id': league['id'],
      'name': league['name'] ?? 'بطولة غير معروفة',
      'logo': league['logo'] ?? '',
      'country': country['name'] ?? 'غير محدد',
      'flag': country['flag'] ?? '',
      'type': league['type'] ?? '',
    });
  }

  if (loadedLeagues.isEmpty) {
    throw Exception('لا توجد بطولات متاحة حالياً');
  }

  if (!mounted) return;

  setState(() {
    leagues = loadedLeagues;
    isLoading = false;
  });
} catch (e) {
  if (!mounted) return;

  setState(() {
    errorMessage = 'تعذر تحميل البطولات.\n${e.toString()}';
    isLoading = false;
  });
}

}

List<Map<String, dynamic>> get filteredLeagues {
if (searchQuery.trim().isEmpty) return leagues;

final query = searchQuery.trim().toLowerCase();

return leagues.where((league) {
  final name = league['name'].toString().toLowerCase();
  final country = league['country'].toString().toLowerCase();

  return name.contains(query) || country.contains(query);
}).toList();

}

void showLeagueDetails(Map<String, dynamic> league) {
showModalBottomSheet(
context: context,
backgroundColor: Theme.of(context).cardColor,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(22),
),
),
builder: (context) {
final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: primary.withOpacity(0.10),
            child: _LeagueLogo(
              logo: league['logo'].toString(),
              size: 48,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            league['name'].toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('الدولة: ${league['country']}'),
          const SizedBox(height: 6),
          Text('رقم البطولة: ${league['id']}'),
          const SizedBox(height: 20),
        ],
      ),
    );
  },
);

}

@override
Widget build(BuildContext context) {
final primary = Theme.of(context).colorScheme.primary;

return Column(
  children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن بطولة أو دولة...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),

    Expanded(
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: loadLeagues,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadLeagues,
                  child: filteredLeagues.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(
                              child: Text('لم يتم العثور على بطولات'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            14, 8, 14, 20,
                          ),
                          itemCount: filteredLeagues.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final league = filteredLeagues[index];

                            return Material(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(15),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () =>
                                    showLeagueDetails(league),
                                child: Container(
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor:
                                            primary.withOpacity(0.08),
                                        child: _LeagueLogo(
                                          logo: league['logo'].toString(),
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 13),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              league['name'].toString(),
                                              style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                _CountryFlag(
                                                  flag: league['flag']
                                                      .toString(),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  league['country']
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_left,
                                        color: primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    ),
  ],
);

}
}

class _LeagueLogo extends StatelessWidget {
final String logo;
final double size;

const _LeagueLogo({
required this.logo,
required this.size,
});

@override
Widget build(BuildContext context) {
if (logo.isEmpty) {
return Icon(
Icons.emoji_events_outlined,
size: size,
color: Theme.of(context).colorScheme.primary,
);
}

return Image.network(
  logo,
  width: size,
  height: size,
  fit: BoxFit.contain,
  errorBuilder: (_, __, ___) {
    return Icon(
      Icons.emoji_events_outlined,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );
  },
);

}
}

class _CountryFlag extends StatelessWidget {
final String flag;

const _CountryFlag({required this.flag});

@override
Widget build(BuildContext context) {
if (flag.isEmpty) return const SizedBox.shrink();

return Image.network(
  flag,
  width: 18,
  height: 13,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
);

}
}
