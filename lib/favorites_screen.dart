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
  String? errorMessage;

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
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final savedTeams = await service.getFavoriteTeamDetails();
      final savedLeagues = await service.getFavoriteLeagueDetails();

      if (!mounted) return;

      setState(() {
        teams = savedTeams;
        leagues = savedLeagues;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'تعذر تحميل المفضلة.';
        isLoading = false;
      });
    }
  }

  Future<void> removeFavorite(
    String id,
    bool isTeam,
  ) async {
    if (id.isEmpty) return;

    try {
      if (isTeam) {
        await service.removeTeam(id);
      } else {
        await service.removeLeague(id);
      }

      await loadFavorites();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حذف العنصر من المفضلة.'),
        ),
      );
    }
  }

  Future<void> confirmRemove(
    String id,
    String name,
    bool isTeam,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف من المفضلة'),
          content: Text('هل تريد حذف $name من المفضلة؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await removeFavorite(id, isTeam);
    }
  }

  Widget buildEmptyState(String title, bool isTeam) {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTeam
                    ? Icons.shield_outlined
                    : Icons.emoji_events_outlined,
                size: 48,
                color: primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف الفرق والبطولات التي تفضلها لتجدها هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
        isTeam,
      );
    }

    return RefreshIndicator(
      onRefresh: loadFavorites,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(15),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];

          final id = item['id']?.toString() ?? '';
          final name = item['name']?.toString() ?? 'غير معروف';
          final logo = item['logo']?.toString() ?? '';

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context)
                    .dividerColor
                    .withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: logo.isEmpty
                      ? Icon(
                          isTeam
                              ? Icons.shield_outlined
                              : Icons.emoji_events_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 29,
                        )
                      : Image.network(
                          logo,
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

                const SizedBox(width: 13),

                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'حذف من المفضلة',
                  onPressed: () {
                    confirmRemove(id, name, isTeam);
                  },
                  icon: const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 28,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        const SizedBox(height: 12),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            dividerColor
