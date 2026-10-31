import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_teams_screen.dart';

class OnboardingLeaguesScreen extends StatefulWidget {
  const OnboardingLeaguesScreen({super.key});

  @override
  State<OnboardingLeaguesScreen> createState() => _OnboardingLeaguesScreenState();
}

class _OnboardingLeaguesScreenState extends State<OnboardingLeaguesScreen> {
  final List> leagues = const [
    {'code': '2', 'name': 'دوري أبطال أوروبا', 'emoji': '🏆'},
    {'code': '39', 'name': 'الدوري الإنجليزي', 'emoji': '🏴󠁧󠁢󠁥󠁮󠁧󠁿'},
    {'code': '140', 'name': 'الدوري الإسباني', 'emoji': '🇪🇸'},
    {'code': '135', 'name': 'الدوري الإيطالي', 'emoji': '🇮🇹'},
    {'code': '78', 'name': 'الدوري الألماني', 'emoji': '🇩🇪'},
    {'code': '61', 'name': 'الدوري الفرنسي', 'emoji': '🇫🇷'},
    {'code': '200', 'name': 'البطولة المغربية', 'emoji': '🇲🇦'},
    {'code': '3', 'name': 'الدوري الأوروبي', 'emoji': '🌍'},
  ];

  final Set<String> selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 8),
              child: Text(
                'اختر دورياتك المفضلة',
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
                'يمكنك اختيار أكثر من دوري، وبدون حد أدنى',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: leagues.length,
                itemBuilder: (context, index) {
                  final league = leagues[index];
                  final code = league['code']!;
                  final isSelected = selected.contains(code);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selected.remove(code);
                        } else {
                          selected.add(code);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(league['emoji']!, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              league['name']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? AppColors.gold : AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await OnboardingService.instance.saveLeagues(selected.toList());
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OnboardingTeamsScreen(
                          selectedLeagues: selected.toList(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    selected.isEmpty ? 'تخطي' : 'التالي (${selected.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
