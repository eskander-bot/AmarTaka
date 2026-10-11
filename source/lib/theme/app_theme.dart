import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0E7C66);
  static const accent = Color(0xFFF0A500);
  static const income = Color(0xFF1FA97C);
  static const expense = Color(0xFFE4572E);
  static const amoledBg = Color(0xFF000000);
  static const amoledSurface = Color(0xFF101414);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F6F7),
          foregroundColor: Color(0xFF1A2327),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      );

  static ThemeData get amoled => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(surface: AppColors.amoledSurface),
        scaffoldBackgroundColor: AppColors.amoledBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.amoledBg,
          foregroundColor: Color(0xFFE8EDEE),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: AppColors.amoledSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      );
}
