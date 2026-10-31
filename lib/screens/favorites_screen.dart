import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _favoriteTeams = [];
  List<String> _favoriteLeagues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final teams = await OnboardingService.instance.getTeams();
    final leagues = await OnboardingService.instance.getLeagues();
    setState(() {
      _favoriteTeams = teams;
      _favoriteLeagues = leagues;
      _isLoading = false;
    });
  }

  Future<void> _removeTeam(String team) async {
    setState(() {
      _favoriteTeams.remove(team);
    });
    await OnboardingService.instance.saveTeams(_favoriteTeams);
  }

  Future<void> _removeLeague(String league) async {
    setState(() {
      _favoriteLeagues.remove(league);
    });
    await OnboardingService.instance.saveLeagues(_favoriteLeagues);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: const Text(
          'المفضلة',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.muted,
          tabs: [
            Tab(text: 'الفرق (${_favoriteTeams.length})'),
            Tab(text: 'الدوريات (${_favoriteLeagues.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // قائمة الفرق المفضلة
          _favoriteTeams.isEmpty
              ? _buildEmptyState('لا توجد فرق في المفضلة حالياً')
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _favoriteTeams.length,
                    itemBuilder: (context, index) {
                      final team = _favoriteTeams[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.sports_soccer, color: AppColors.gold),
                          title: Text(
                            team,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _removeTeam(team),
                          ),
                        ),
                      );
                    },
                  ),
                ),

          // قائمة الدوريات المفضلة
          _favoriteLeagues.isEmpty
              ? _buildEmptyState('لا توجد دوريات في المفضلة حالياً')
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _favoriteLeagues.length,
                    itemBuilder: (context, index) {
                      final leagueCode = _favoriteLeagues[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events_outlined, color: AppColors.gold),
                          title: Text(
                            leagueCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _removeLeague(leagueCode),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 55, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
        ],
      ),
    );
  }
}
