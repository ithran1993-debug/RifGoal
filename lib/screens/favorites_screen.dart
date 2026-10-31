import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import 'league_detail_screen.dart';
import 'team_detail_screen.dart';

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

  // دعم المعرفات الرقمية الخاصة بـ API-Sports والرموز القديمة معاً
  final Map<String, String> leagueNames = const {
    '2': 'دوري أبطال أوروبا',
    'CL': 'دوري أبطال أوروبا',
    '39': 'الدوري الإنجليزي',
    'PL': 'الدوري الإنجليزي',
    '140': 'الدوري الإسباني',
    'PD': 'الدوري الإسباني',
    '135': 'الدوري الإيطالي',
    'SA': 'الدوري الإيطالي',
    '78': 'الدوري الألماني',
    'BL1': 'الدوري الألماني',
    '61': 'الدوري الفرنسي',
    'FL1': 'الدوري الفرنسي',
    '3': 'الدوري الأوروبي',
    'EL': 'الدوري الأوروبي',
    '200': 'البطولة المغربية',
    'BOTOLA': 'البطولة المغربية',
  };

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
    if (mounted) {
      setState(() {
        _favoriteTeams = teams;
        _favoriteLeagues = leagues;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeTeam(String team) async {
    setState(() => _favoriteTeams.remove(team));
    await OnboardingService.instance.saveTeams(_favoriteTeams);
  }

  Future<void> _removeLeague(String league) async {
    setState(() => _favoriteLeagues.remove(league));
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
        title: const Text('المفضلة', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
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
          // الفرق
          _favoriteTeams.isEmpty
              ? _buildEmptyState('لا توجد فرق في المفضلة حالياً')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _favoriteTeams.length,
                  itemBuilder: (context, index) {
                    final team = _favoriteTeams[index];
                    final badgeUrl = AppConstants.teamBadges[team];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TeamDetailScreen(teamName: team)),
                          );
                        },
                        leading: badgeUrl != null
                            ? Image.network(
                                badgeUrl,
                                width: 32,
                                height: 32,
                                errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, color: AppColors.gold),
                              )
                            : const Icon(Icons.sports_soccer, color: AppColors.gold, size: 28),
                        title: Text(team, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: const Text('اضغط لعرض المباريات والنتائج', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _removeTeam(team),
                        ),
                      ),
                    );
                  },
                ),

          // الدوريات
          _favoriteLeagues.isEmpty
              ? _buildEmptyState('لا توجد دوريات في المفضلة حالياً')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _favoriteLeagues.length,
                  itemBuilder: (context, index) {
                    final leagueCode = _favoriteLeagues[index];
                    final displayName = leagueNames[leagueCode] ?? leagueCode;
                    final badgeUrl = AppConstants.leagueBadges[leagueCode];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LeagueDetailScreen(leagueName: displayName, leagueCode: leagueCode),
                            ),
                          );
                        },
                        leading: badgeUrl != null
                            ? Image.network(
                                badgeUrl,
                                width: 30,
                                height: 30,
                                errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, color: AppColors.gold),
                              )
                            : const Icon(Icons.emoji_events, color: AppColors.gold, size: 28),
                        title: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: const Text('اضغط لعرض المباريات والترتيب', style: TextStyle(color: AppColors.muted, fontSize:
