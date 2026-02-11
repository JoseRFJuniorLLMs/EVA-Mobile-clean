import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeHeadline = 32.0;

  static const double recommendedTouchTargetSize = 48.0;

  static ThemeData buildTheme(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final isBoldText = MediaQuery.boldTextOf(context);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(context, textScaleFactor, isBoldText),
      buttonTheme: const ButtonThemeData(
        minWidth: recommendedTouchTargetSize,
        height: recommendedTouchTargetSize,
      ),
    );
  }

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
    ),
  );

  static TextTheme _buildTextTheme(
    BuildContext context,
    double textScaleFactor,
    bool isBoldText, {
    bool isDark = false,
  }) {
    final clampedScale = textScaleFactor.clamp(0.8, 2.0);
    final fontWeight = isBoldText ? FontWeight.bold : FontWeight.normal;
    final textColor = isDark ? const Color(0xFFFFFFFF) : Colors.white;

    return TextTheme(
      displayLarge: TextStyle(fontSize: fontSizeHeadline * clampedScale, fontWeight: fontWeight, color: textColor),
      displayMedium: TextStyle(fontSize: fontSizeTitle * clampedScale, fontWeight: fontWeight, color: textColor),
      headlineLarge: TextStyle(fontSize: fontSizeTitle * clampedScale, fontWeight: fontWeight, color: textColor),
      headlineMedium: TextStyle(fontSize: fontSizeLarge * clampedScale, fontWeight: fontWeight, color: textColor),
      titleLarge: TextStyle(fontSize: fontSizeLarge * clampedScale, fontWeight: fontWeight, color: textColor),
      titleMedium: TextStyle(fontSize: fontSizeBody * clampedScale, fontWeight: fontWeight, color: textColor),
      bodyLarge: TextStyle(fontSize: fontSizeBody * clampedScale, fontWeight: fontWeight, color: textColor),
      bodyMedium: TextStyle(fontSize: fontSizeBody * clampedScale, fontWeight: fontWeight, color: isDark ? const Color(0xFFE0E0E0) : Colors.white70),
      labelLarge: TextStyle(fontSize: fontSizeBody * clampedScale, fontWeight: fontWeight, color: textColor),
      labelMedium: TextStyle(fontSize: fontSizeSmall * clampedScale, fontWeight: fontWeight, color: isDark ? const Color(0xFFE0E0E0) : Colors.white70),
    );
  }
}
