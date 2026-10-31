import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> _favoriteTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    // قراءة الفرق المحفوظة من OnboardingService
    final teams = await OnboardingService.instance.getSavedTeams();
    setState(() {
      _favoriteTeams = teams;
      _isLoading = false;
    });
  }

  Future<void> _removeTeam(String teamName) async {
    setState(() {
      _favoriteTeams.remove(teamName);
    });
    await OnboardingService.instance.saveTeams(_favoriteTeams);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (_favoriteTeams.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 60, color: AppColors.muted),
              SizedBox(height: 12),
              Text(
                'لا توجد فرق في المفضلة حالياً',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _loadFavorites,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _favoriteTeams.length,
          itemBuilder: (context, index) {
            final team = _favoriteTeams[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.sports_soccer, color: AppColors.gold),
                ),
                title: Text(
                  team,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
    );
  }
}
