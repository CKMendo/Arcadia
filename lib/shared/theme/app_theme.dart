import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData buildArcadiaTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.lakeCyan,
      onPrimary: Color(0xFF06111D),
      secondary: AppColors.duneSand,
      onSecondary: Color(0xFF06111D),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimary,
      error: AppColors.scoreBirdie,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white),
      displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      titleSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodySmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      labelMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      labelSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.appBarDark,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lakeCyan,
        foregroundColor: const Color(0xFF06111D),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lakeCyan,
        side: const BorderSide(color: AppColors.lakeCyan, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lakeCyan, width: 2.0),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 17),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.cardBorder,
      thickness: 1.2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.appBarDark,
      selectedItemColor: AppColors.lakeCyan,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
      selectedLabelStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
      unselectedLabelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      selectedIconTheme: IconThemeData(size: 32),
      unselectedIconTheme: IconThemeData(size: 28),
    ),
  );
}
