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

  // فرق حسب الدوريات (يمكن توسيعها لاحقاً)
  final Map<String, List<Map<String, String>>> teamsByLeague = const {
    'CL': [
      {'name': 'ريال مدريد', 'emoji': '⚪'},
      {'name': 'برشلونة', 'emoji': '🔵'},
      {'name': 'مانشستر سيتي', 'emoji': '🩵'},
      {'name': 'بايرن ميونخ', 'emoji': '🔴'},
      {'name': 'باريس سان جيرمان', 'emoji': '🔵'},
      {'name': 'ليفربول', 'emoji': '🔴'},
    ],
    'PL': [
      {'name': 'مانشستر سيتي', 'emoji': '🩵'},
      {'name': 'آرسنال', 'emoji': '🔴'},
      {'name': 'ليفربول', 'emoji': '🔴'},
      {'name': 'تشيلسي', 'emoji': '🔵'},
      {'name': 'مانشستر يونايتد', 'emoji': '🔴'},
      {'name': 'توتنهام', 'emoji': '⚪'},
    ],
    'PD': [
      {'name': 'ريال مدريد', 'emoji': '⚪'},
      {'name': 'برشلونة', 'emoji': '🔵'},
      {'name': 'أتلتيكو مدريد', 'emoji': '🔴'},
      {'name': 'إشبيلية', 'emoji': '⚪'},
    ],
    'SA': [
      {'name': 'يوفنتوس', 'emoji': '⚪'},
      {'name': 'ميلان', 'emoji': '🔴'},
      {'name': 'إنتر', 'emoji': '🔵'},
      {'name': 'نابولي', 'emoji': '🔵'},
    ],
    'BL1': [
      {'name': 'بايرن ميونخ', 'emoji': '🔴'},
      {'name': 'دورتموند', 'emoji': '🟡'},
      {'name': 'لايبزيغ', 'emoji': '🔴'},
    ],
    'FL1': [
      {'name': 'باريس سان جيرمان', 'emoji': '🔵'},
      {'name': 'مارسيليا', 'emoji': '🔵'},
      {'name': 'ليون', 'emoji': '🔵'},
    ],
    'BOTOLA': [
      {'name': 'الوداد', 'emoji': '🔴'},
      {'name': 'الرجاء', 'emoji': '🟢'},
      {'name': 'الجيش الملكي', 'emoji': '🟢'},
      {'name': 'الفتح', 'emoji': '🟢'},
      {'name': 'حسنية أكادير', 'emoji': '🔴'},
      {'name': 'المغرب الفاسي', 'emoji': '🟡'},
    ],
    'EL': [
      {'name': 'إشبيلية', 'emoji': '⚪'},
      {'name': 'روما', 'emoji': '🟡'},
      {'name': 'آرسنال', 'emoji': '🔴'},
    ],
  };

  List<Map<String, String>> get availableTeams {
    final List<Map<String, String>> teams = [];
    final Set<String> added = {};

    final leagues = widget.selectedLeagues.isEmpty
        ? teamsByLeague.keys.toList()
        : widget.selectedLeagues;

    for (final code in leagues) {
      final list = teamsByLeague[code] ?? [];
      for (final team in list) {
        if (!added.contains(team['name'])) {
          teams.add(team);
          added.add(team['name']!);
        }
      }
    }
    return teams;
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
                        final name = team['name']!;
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
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold.withOpacity(0.15)
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.gold : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(team['emoji']!, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize
