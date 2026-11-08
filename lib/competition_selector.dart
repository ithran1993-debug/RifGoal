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
return SizedBox(
height: 52,
child: ListView.separated(
scrollDirection: Axis.horizontal,
reverse: true,
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 7,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF202B3B)
                : const Color(0xFFF1F3F7),
            borderRadius: BorderRadius.circular(7),
            border: Border(
              bottom: BorderSide(
                color: active
                    ? const Color(0xFFFF9800)
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : const Color(0xFF596575),
              fontSize: 12,
              fontWeight: active
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ),
      );
    },
  ),
);

}
}
