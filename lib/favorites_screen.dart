import 'package:flutter/material.dart';
import 'favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
const FavoritesScreen({super.key});

@override
State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
with SingleTickerProviderStateMixin {
final FavoritesService service = FavoritesService();

late TabController tabController;

List<Map<String, dynamic>> teams = [];
List<Map<String, dynamic>> leagues = [];

bool isLoading = true;

@override
void initState() {
super.initState();
tabController = TabController(length: 2, vsync: this);
loadFavorites();
}

@override
void dispose() {
tabController.dispose();
super.dispose();
}

Future<void> loadFavorites() async {
setState(() {
isLoading = true;
});

final savedTeams = await service.getFavoriteTeamDetails();
final savedLeagues = await service.getFavoriteLeagueDetails();

if (!mounted) return;

setState(() {
  teams = savedTeams;
  leagues = savedLeagues;
  isLoading = false;
});

}

Future<void> removeTeam(String id) async {
await service.removeTeam(id);
await loadFavorites();
}

Future<void> removeLeague(String id) async {
await service.removeLeague(id);
await loadFavorites();
}

Widget buildEmptyState(String title) {
return Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.star_border_rounded,
size: 70,
color: Theme.of(context).colorScheme.primary,
),
const SizedBox(height: 14),
Text(
title,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 7),
Text(
'أضف ما تفضله ليظهر هنا.',
style: TextStyle(
color: Theme.of(context).colorScheme.onSurfaceVariant,
),
),
],
),
);
}

Widget buildFavoriteList(
List<Map<String, dynamic>> items,
bool isTeam,
) {
if (items.isEmpty) {
return buildEmptyState(
isTeam ? 'لا توجد فرق مفضلة' : 'لا توجد بطولات مفضلة',
);
}

return ListView.separated(
  padding: const EdgeInsets.all(14),
  itemCount: items.length,
  separatorBuilder: (_, __) => const SizedBox(height: 9),
  itemBuilder: (context, index) {
    final item = items[index];

    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'غير معروف';
    final logo = item['logo']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.08),
            child: logo.isEmpty
                ? Icon(
                    isTeam
                        ? Icons.shield_outlined
                        : Icons.emoji_events_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : ClipOval(
                    child: Image.network(
                      logo,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          isTeam
                              ? Icons.shield_outlined
                              : Icons.emoji_events_outlined,
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            tooltip: 'حذف من المفضلة',
            onPressed: () {
              if (isTeam) {
                removeTeam(id);
              } else {
                removeLeague(id);
              }
            },
            icon: const Icon(
              Icons.star,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  },
);

}

@override
Widget build(BuildContext context) {
return Column(
children: [
Material(
color: Theme.of(context).cardColor,
child: TabBar(
controller: tabController,
tabs: const [
Tab(
icon: Icon(Icons.shield_outlined),
text: 'الفرق',
),
Tab(
icon: Icon(Icons.emoji_events_outlined),
text: 'البطولات',
),
],
),
),
Expanded(
child: isLoading
? const Center(
child: CircularProgressIndicator(),
)
: TabBarView(
controller: tabController,
children: [
buildFavoriteList(teams, true),
buildFavoriteList(leagues, false),
],
),
),
],
);
}
}
