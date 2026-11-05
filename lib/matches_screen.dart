import 'package:flutter/material.dart';

import 'date_selector.dart';
import 'competition_selector.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedCompetition = 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 12),

        DateSelector(
          selectedDate: selectedDate,
          onDateSelected: (date) {
            setState(() {
              selectedDate = date;
            });
          },
        ),

        const SizedBox(height: 12),

        CompetitionSelector(
          selectedCompetition: selectedCompetition,
          onSelected: (competition) {
            setState(() {
              selectedCompetition = competition;
            });
          },
        ),

        const SizedBox(height: 20),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_soccer_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'المباريات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم عرض مباريات هذا اليوم هنا بعد ربط خدمة المباريات.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF9AA0A6)
                          : const Color(0xFF5F6368),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
