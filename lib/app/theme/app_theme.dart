import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get light {
    final textColor = AppColors.secondary900;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.secondary50,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary5,
        brightness: Brightness.light,
        primary: AppColors.primary5,
        secondary: AppColors.secondary700,
        surface: AppColors.white,
        error: AppColors.primary7,
      ),
      textTheme: AppTypography.textTheme(textColor),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.secondary900,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    final textColor = AppColors.secondary50;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.dark0,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary5,
        brightness: Brightness.dark,
        primary: AppColors.primary5,
        secondary: AppColors.secondary300,
        surface: AppColors.dark1,
        error: AppColors.dark9,
      ),
      textTheme: AppTypography.textTheme(textColor),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dark1,
        foregroundColor: AppColors.secondary50,
        elevation: 0,
      ),
    );
  }
}
