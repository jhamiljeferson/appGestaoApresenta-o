import 'package:flutter/material.dart';

class AppColors {
  static const Color blueLight = Color(0xFFE3F0FF);
  static const Color blue = Color(0xFF1976D2);
  static const Color blueDark = Color(0xFF0D47A1);
  static const Color blueAccent = Color(0xFF42A5F5);
  static const Color background = Color(0xFFF5F8FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF5C6F8C);
  static const Color error = Color(0xFFD32F2F);
}

final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.blue,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.light(
    primary: AppColors.blue,
    primaryContainer: AppColors.blueLight,
    secondary: AppColors.blueAccent,
    background: AppColors.background,
    error: AppColors.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.blue,
    foregroundColor: Colors.white,
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: Colors.white,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 3,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    shadowColor: AppColors.blueLight,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.blueLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.blueAccent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.blue),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      elevation: 2,
      shadowColor: AppColors.blueLight,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.blue,
    ),
  ),
  iconTheme: const IconThemeData(color: AppColors.blueAccent),
  dividerColor: AppColors.blueLight,
);
