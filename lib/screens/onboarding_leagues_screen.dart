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

  String getLeagueName(String code) {
    switch (code) {
      case '2':
        return '\u062f\u0648\u0631\u064a \u0623\u0628\u0637\u0627\u0644 \u0623\u0648\u0631\u0648\u0628\u0627';
      case '39':
        return '\u0627\u0644\u062f\u0648\u0631\u064a \u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a';
      case '140':
        return '\u0627\u0644\u062f\u0648\u0631\u064a \u0627\u0644\u0625\u0633\u0628\u0627\u0646\u064a';
      case '135':
        return '\u0627\u0644\u062f\u0648\u0631\u064a \u0627\u0644\u0625\u064a\u0637\u0627\u0644\u064a';
      case '78':
        return '\u0627\u0644\u062f\u0648\u0631\u064a \u0627\u0644\u0623\u0644\u0645\u0627\u0646\u064a';
      case '61':
        return '\u0627\u0644\u062f\u0648\u0631\u064a \u0627\u0644\u0641\u0631\u0646\u0633\u064a';
      case '200':
        return '\u0627\u0644\u0628\u0637\u0648\u0644\u0629 \u0627\u0644\u0645\u063a\u0631\u0628\u064a\u0629';
      case '3':
        return '\u0627\u0644\u062f\u0648\u0631\u064a \u0627\u0644\u0623\u0648\u0631\u0648\u0628\u064a';
      default:
        return '';
    }
  }

  String getLeagueEmoji(String code) {
    switch (code) {
      case '2':
        return '🏆';
      case '39':
        return '🏴󠁧󠁢󠁥󠁮󠁧󠁿';
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
                '\u0627\u062e\u062a\u0631 \u062f\u0648\u0631\u064a\u0627\u062a\u0643 \u0627\u0644\u0645\u0641\u0636\u0644\u0629',
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
                '\u064a\u0645\u0643\u0646\u0643 \u0627\u062e\u062a\u064a\u0627\u0631 \u0623\u0643\u062b\u0631 \u0645\u0646 \u062f\u0648\u0631\u064a\u060c \u0648\u0628\u062f\u0648\u0646 \u062d\u062f \u0623\u062f\u0646\u0649',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
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
                          Text(getLeagueEmoji(code), style: const TextStyle(fontSize: 28)),
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
                    selected.isEmpty
                        ? '\u062a\u062e\u0637\u064a'
                        : '\u0627\u0644\u062a\u0627\u0644\u064a (${selected.length})',
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
