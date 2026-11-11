import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  static const Color navy = Color(0xFF37474F);
  static const Color orange = Color(0xFFFF9800);

  static const List<String> days = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _dayLabel(DateTime date) {
    final today = DateTime.now();

    final selected = DateTime(date.year, date.month, date.day);
    final current = DateTime(today.year, today.month, today.day);

    if (_sameDay(selected, current)) return 'اليوم';

    if (_sameDay(
      selected,
      current.subtract(const Duration(days: 1)),
    )) {
      return 'أمس';
    }

    if (_sameDay(
      selected,
      current.add(const Duration(days: 1)),
    )) {
      return 'الغد';
    }

    return days[date.weekday - 1];
  }

  String _dateLabel(DateTime date) {
    return '${date.day} ${months[date.month - 1]}';
  }

  Future<void> _openCalendar(BuildContext context) async {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'اختر تاريخ المباريات',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: orange,
                brightness:
                    isDark ? Brightness.dark : Brightness.light,
              ).copyWith(
                primary: orange,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      color: navy,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
              ),
              itemCount: 15,
              itemBuilder: (context, index) {
                final today = DateTime.now();

                final date = DateTime(
                  today.year,
                  today.month,
                  today.day,
                ).add(Duration(days: index - 7));

                final isSelected = _sameDay(
                  date,
                  selectedDate,
                );

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onDateSelected(date),
                  child: SizedBox(
                    width: 76,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayLabel(date),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _dateLabel(date),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFCFD8DC),
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          Container(
                            height: 3,
                            width: 43,
                            decoration: const BoxDecoration(
                              color: orange,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(3),
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
          Container(
            width: 1,
            height: 35,
            color: Colors.white.withOpacity(0.15),
          ),
          IconButton(
            onPressed: () => _openCalendar(context),
            tooltip: 'اختيار التاريخ',
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}
