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
      {'name': 'ريال مدريد', 'logo': 'https://crests.football-data.org/86.png'},
      {'name': 'برشلونة', 'logo': 'https://crests.football-data.org/81.png'},
      {'name': 'مانشستر سيتي', 'logo': 'https://crests.football-data.org/65.png'},
      {'name': 'بايرن ميونخ', 'logo': 'https://crests.football-data.org/5.png'},
      {'name': 'باريس سان جيرمان', 'logo': 'https://crests.football-data.org/524.png'},
      {'name': 'ليفربول', 'logo': 'https://crests.football-data.org/64.png'},
    ],
    // الدوري الإنجليزي
    '39': [
      {'name': 'مانشستر سيتي', 'logo': 'https://crests.football-data.org/65.png'},
      {'name': 'آرسنال', 'logo': 'https://crests.football-data.org/57.png'},
      {'name': 'ليفربول', 'logo': 'https://crests.football-data.org/64.png'},
      {'name': 'تشيلسي', 'logo': 'https://crests.football-data.org/61.png'},
      {'name': 'مانشستر يونايتد', 'logo': 'https://crests.football-data.org/66.png'},
      {'name': 'توتنهام', 'logo': 'https://crests.football-data.org/73.png'},
    ],
    // الدوري الإسباني
    '140': [
      {'name': 'ريال مدريد', 'logo': 'https://crests.football-data.org/86.png'},
      {'name': 'برشلونة', 'logo': 'https://crests.football-data.org/81.png'},
      {'name': 'أتلتيكو مدريد', 'logo': 'https://crests.football-data.org/78.png'},
      {'name': 'إشبيلية', 'logo': 'https://crests.football-data.org/559.png'},
    ],
    // الدوري الإيطالي
    '135': [
      {'name': 'يوفنتوس', 'logo': 'https://crests.football-data.org/109.png'},
      {'name': 'ميلان', 'logo': 'https://crests.football-data.org/98.png'},
      {'name': 'إنتر', 'logo': 'https://crests.football-data.org/108.png'},
      {'name': 'نابولي', 'logo': 'https://crests.football-data.org/113.png'},
    ],
    // الدوري الألماني
    '78': [
      {'name': 'بايرن ميونخ', 'logo': 'https://crests.football-data.org/5.png'},
      {'name': 'دورتموند', 'logo': 'https://crests.football-data.org/4.png'},
      {'name': 'لايبزيغ', 'logo': 'https://crests.football-data.org/721.png'},
    ],
    // الدوري الفرنسي
    '61': [
      {'name': 'باريس سان جيرمان', 'logo': 'https://crests.football-data.org/524.png'},
      {'name': 'مارسيليا', 'logo': 'https://crests.football-data.org/516.png'},
      {'name': 'ليون', 'logo': 'https://crests.football-data.org/523.png'},
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
      {'name': 'إشبيلية', 'logo': 'https://crests.football-data.org/559.png'},
      {'name': 'روما', 'logo': 'https://crests.football-data.org/100.png'},
      {'name': 'آرسنال', 'logo': 'https://crests.football-data.org/57.png'},
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
                              borderRadius: BorderRadius.circular(1
