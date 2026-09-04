import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          surface: AppColors.lightBackground,
          onSurface: AppColors.lightText,
          onSurfaceVariant: AppColors.lightSecondary,
        ),
        textTheme: _textTheme(AppColors.lightText, AppColors.lightSecondary),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.darkBackground,
          onSurface: AppColors.darkText,
          onSurfaceVariant: AppColors.darkSecondary,
        ),
        textTheme: _textTheme(AppColors.darkText, AppColors.darkSecondary),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      );

  /// Returns responsive horizontal padding proportional to screen width
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.07).clamp(16.0, 36.0);
  }

  /// Returns responsive vertical padding proportional to screen height
  static double verticalPadding(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.025).clamp(16.0, 32.0);
  }

  /// Returns responsive clock font size
  static double responsiveClockFontSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.12).clamp(38.0, 64.0);
  }

  /// Returns responsive home favorites font size
  static double responsiveAppTitleFontSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.05).clamp(17.0, 24.0);
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        color: primary,
        letterSpacing: -1.0,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
