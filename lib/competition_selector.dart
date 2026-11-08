import 'package:flutter/material.dart';

class CompetitionSelector extends StatelessWidget {
final String selectedCompetition;
final ValueChanged<String> onSelected;

const CompetitionSelector({
super.key,
required this.selectedCompetition,
required this.onSelected,
});

static const List<Map<String, String>> competitions = [
{'code': 'ALL', 'name': 'الكل'},
{'code': 'CL', 'name': 'أبطال أوروبا'},
{'code': 'PL', 'name': 'إنجلترا'},
{'code': 'PD', 'name': 'إسبانيا'},
{'code': 'SA', 'name': 'إيطاليا'},
{'code': 'BL1', 'name': 'ألمانيا'},
{'code': 'FL1', 'name': 'فرنسا'},
];

@override
Widget build(BuildContext context) {
final primary = Theme.of(context).colorScheme.primary;
final isDark = Theme.of(context).brightness == Brightness.dark;

return SizedBox(
  height: 48,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    reverse: true,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    itemCount: competitions.length,
    separatorBuilder: (_, __) => const SizedBox(width: 7),
    itemBuilder: (context, index) {
      final competition = competitions[index];
      final code = competition['code']!;
      final name = competition['name']!;
      final active = code == selectedCompetition;

      return GestureDetector(
        onTap: () => onSelected(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? primary
                : (isDark
                    ? const Color(0xFF2A2E36)
                    : const Color(0xFFF1F3F4)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    },
  ),
);

}
}
