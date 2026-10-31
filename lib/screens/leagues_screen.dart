
import 'package:flutter/material.dart';

import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_teams_screen.dart';

class OnboardingLeaguesScreen extends StatefulWidget {
  const OnboardingLeaguesScreen({super.key});

  @override
  State<OnboardingLeaguesScreen> createState() =>
      _OnboardingLeaguesScreenState();
}

class _OnboardingLeaguesScreenState
    extends State<OnboardingLeaguesScreen> {
  final List<String> codes = const [
    '2',
    '39',
    '140',
    '135',
    '78',
    '61',
    '200',
    '3',
  ];

  final Set<String> selected = {};

  bool isSaving = false;

  String getLeagueName(String code) {
    switch (code) {
      case '2':
        return 'دوري أبطال أوروبا';
      case '39':
        return 'الدوري الإنجليزي';
      case '140':
        return 'الدوري الإسباني';
      case '135':
        return 'الدوري الإيطالي';
      case '78':
        return 'الدوري الألماني';
      case '61':
        return 'الدوري الفرنسي';
      case '200':
        return 'البطولة المغربية';
      case '3':
        return 'الدوري الأوروبي';
      default:
        return 'دوري غير معروف';
    }
  }

  String getLeagueEmoji(String code) {
    switch (code) {
      case '2':
        return '🏆';
      case '39':
        return '🏴';
      case '140':
        return '🇪🇸';
      case '135':
        return '🇮🇹';
      case '78':
        return '🇩🇪';
      case '61':
        return '🇫🇷';
      case '200':
        return '🇲🇦';
      case '3':
        return '🌍';
      default:
        return '⚽';
    }
  }

  Future<void> continueToTeams() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    final leagues = List<String>.from(selected);

    try {
      await OnboardingService.instance.saveLeagues(leagues);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingTeamsScreen(
            selectedLeagues: leagues,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ الدوريات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

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
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: codes.length,
                itemBuilder: (context, index) {
                  final code = codes[index];
                  final isSelected = selected.contains(code);

                  return GestureDetector(
                    onTap: isSaving
                        ? null
                        : () {
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withOpacity(0.15)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            getLeagueEmoji(code),
                            style: const TextStyle(fontSize: 28),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Text(
                              getLeagueName(code),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),

                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? AppColors.gold
                                : AppColors.muted,
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
                  onPressed: isSaving ? null : continueToTeams,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor:
                        AppColors.gold.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : Text(
                          selected.isEmpty
                              ? 'تخطي'
                              : 'التالي (${selected.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
