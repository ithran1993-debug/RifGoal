import 'package:flutter/material.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  String selectedLeague = 'الدوري الإنجليزي';

  final List<String> leagues = [
    'الدوري الإنجليزي',
    'الدوري الإسباني',
    'الدوري الإيطالي',
    'الدوري الألماني',
    'الدوري الفرنسي',
    'البطولة المغربية',
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonFormField<String>(
            value: selectedLeague,
            decoration: InputDecoration(
              labelText: 'اختر البطولة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: leagues.map((league) {
              return DropdownMenuItem(
                value: league,
                child: Text(league),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedLeague = value;
                });
              }
            },
          ),
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
                    Icons.leaderboard_outlined,
                    size: 64,
                    color: primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ترتيب الفرق',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيظهر الترتيب الحقيقي للبطولة بعد ربط بيانات API.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
