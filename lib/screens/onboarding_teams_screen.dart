import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class OnboardingTeamsScreen extends StatefulWidget {
  final List<String> selectedLeagues;

  const OnboardingTeamsScreen({super.key, required this.selectedLeagues});

  @override
  State<OnboardingTeamsScreen> createState() => _OnboardingTeamsScreenState();
}

class _OnboardingTeamsScreenState extends State<OnboardingTeamsScreen> {
  final Set<String> selected = {};

  final Map<String, dynamic> teamsByLeague = const {
    // دوري أبطال أوروبا
    '2': [
      {'name': 'ريال مدريد', 'logo': 'https://media.api-sports.io/football/teams/541.png'},
      {'name': 'برشلونة', 'logo': 'https://media.api-sports.io/football/teams/529.png'},
      {'name': 'مانشستر سيتي', 'logo': 'https://media.api-sports.io/football/teams/50.png'},
      {'name': 'بايرن ميونخ', 'logo': 'https://media.api-sports.io/football/teams/157.png'},
      {'name': 'باريس سان جيرمان', 'logo': 'https://media.api-sports.io/football/teams/85.png'},
      {'name': 'ليفربول', 'logo': 'https://media.api-sports.io/football/teams/40.png'},
    ],
    // الدوري الإنجليزي
    '39': [
      {'name': 'مانشستر سيتي', 'logo': 'https://media.api-sports.io/football/teams/50.png'},
      {'name': 'آرسنال', 'logo': 'https://media.api-sports.io/football/teams/42.png'},
      {'name': 'ليفربول', 'logo': 'https://media.api-sports.io/football/teams/40.png'},
      {'name': 'تشيلسي', 'logo': 'https://media.api-sports.io/football/teams/49.png'},
      {'name': 'مانشستر يونايتد', 'logo': 'https://media.api-sports.io/football/teams/33.png'},
      {'name': 'توتنهام', 'logo': 'https://media.api-sports.io/football/teams/47.png'},
    ],
    // الدوري الإسباني
    '140': [
      {'name': 'ريال مدريد', 'logo': 'https://media.api-sports.io/football/teams/541.png'},
      {'name': 'برشلونة', 'logo': 'https://media.api-sports.io/football/teams/529.png'},
      {'name': 'أتلتيكو مدريد', 'logo': 'https://media.api-sports.io/football/teams/530.png'},
      {'name': 'إشبيلية', 'logo': 'https://media.api-sports.io/football/teams/536.png'},
    ],
    // الدوري الإيطالي
    '135': [
      {'name': 'يوفنتوس', 'logo': 'https://media.api-sports.io/football/teams/496.png'},
      {'name': 'ميلان', 'logo': 'https://media.api-sports.io/football/teams/489.png'},
      {'name': 'إنتر', 'logo': 'https://media.api-sports.io/football/teams/505.png'},
      {'name': 'نابولي', 'logo': 'https://media.api-sports.io/football/teams/492.png'},
    ],
    // الدوري الألماني
    '78': [
      {'name': 'بايرن ميونخ', 'logo': 'https://media.api-sports.io/football/teams/157.png'},
      {'name': 'دورتموند', 'logo': 'https://media.api-sports.io/football/teams/165.png'},
      {'name': 'لايبزيغ', 'logo': 'https://media.api-sports.io/football/teams/173.png'},
    ],
    // الدوري الفرنسي
    '61': [
      {'name': 'باريس سان جيرمان', 'logo': 'https://media.api-sports.io/football/teams/85.png'},
      {'name': 'مارسيليا', 'logo': 'https://media.api-sports.io/football/teams/81.png'},
      {'name': 'ليون', 'logo': 'https://media.api-sports.io/football/teams/80.png'},
    ],
    // البطولة المغربية
    '200': [
      {'name': 'الوداد', 'logo': 'https://media.api-sports.io/football/teams/968.png'},
      {'name': 'الرجاء', 'logo': 'https://media.api-sports.io/football/teams/967.png'},
      {'name': 'الجيش الملكي', 'logo': 'https://media.api-sports.io/football/teams/969.png'},
      {'name': 'الفتح', 'logo': 'https://media.api-sports.io/football/teams/970.png'},
      {'name': 'حسنية أكادير', 'logo': 'https://media.api-sports.io/football/teams/971.png'},
      {'name': 'المغرب الفاسي', 'logo': 'https://media.api-sports.io/football/teams/973.png'},
    ],
    // الدوري الأوروبي
    '3': [
      {'name': 'إشبيلية', 'logo': 'https://media.api-sports.io/football/teams/536.png'},
      {'name': 'روما', 'logo': 'https://media.api-sports.io/football/teams/497.png'},
      {'name': 'آرسنال', 'logo': 'https://media.api-sports.io/football/teams/42.png'},
    ],
  };

  List get availableTeams {
    final List teamsList = [];
    final Set addedNames = {};

    final activeLeagues = widget.selectedLeagues.isEmpty
        ? teamsByLeague.keys.toList()
        : widget.selectedLeagues;

    for (final leagueCode in activeLeagues) {
      final currentList = teamsByLeague[leagueCode] as List? ?? [];
      for (final teamItem in currentList) {
        final teamName = teamItem['name']?.toString() ?? '';
        if (!addedNames.contains(teamName)) {
          teamsList.add(teamItem);
          addedNames.add(teamName);
        }
      }
    }
    return teamsList;
  }

  Future<void> _finish() async {
    await OnboardingService.instance.saveTeams(selected.toList());
    await OnboardingService.instance.setDone();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = availableTeams;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 8),
              child: Text(
                'اختر فرقك المفضلة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'بدون حد أدنى — اختر ما تريد أو تخطى',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: teams.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد فرق متاحة',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.4,
                      ),
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final name = team['name']?.toString() ?? '';
                        final logoUrl = team['logo']?.toString() ?? '';
                        final isSelected = selected.contains(name);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selected.remove(name);
                              } else {
                                selected.add(name);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold.withValues(alpha: 0.15)
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.gold : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (logoUrl.isNotEmpty)
                                  Image.network(
                                    logoUrl,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Center(
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.sports_soccer,
                                      size: 26,
                                      color: Colors.white60,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.sports_soccer,
                                    size: 26,
                                    color: Colors.white60,
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? AppColors.gold : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _finish,
                  child: Text(
                    selected.isEmpty ? 'تخطي ومتابعة' : 'متابعة (${selected.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
}
