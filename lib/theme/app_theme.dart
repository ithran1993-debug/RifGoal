import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0D1117);
  static const Color card = Color(0xFF161B22);
  static const Color border = Color(0xFF30363D);
  static const Color text = Color(0xFFE6EDF3);
  static const Color muted = Color(0xFF8B949E);
  static const Color gold = Color(0xFFC9A227);
  static const Color goldDark = Color(0xFFA67C00);
  static const Color live = Color(0xFFF85149);
  static const Color green = Color(0xFF3FB950);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldDark,
        surface: AppColors.card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
