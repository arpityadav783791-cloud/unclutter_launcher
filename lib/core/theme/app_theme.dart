import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

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
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.lightBackground,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.lightBackground,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.topXl),
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
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF111111),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF111111),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.topXl),
        ),
      );

  /// Returns responsive horizontal padding bounded between 16 and 32dp
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.06).clamp(16.0, 32.0);
  }

  /// Returns responsive vertical padding bounded between 16 and 32dp
  static double verticalPadding(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.025).clamp(16.0, 32.0);
  }

  /// Returns responsive clock font size bounded for small to large phones
  static double responsiveClockFontSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.12).clamp(40.0, 60.0);
  }

  /// Returns responsive app title font size bounded to prevent line breaks
  static double responsiveAppTitleFontSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.05).clamp(18.0, 22.0);
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: AppTypography.clock.copyWith(color: primary),
      headlineMedium: AppTypography.screenTitle.copyWith(color: primary),
      bodyLarge: AppTypography.appTitle.copyWith(color: primary),
      bodyMedium: AppTypography.body.copyWith(color: secondary),
      bodySmall: AppTypography.bodySmall.copyWith(color: secondary),
      labelLarge: AppTypography.button.copyWith(color: secondary),
      labelSmall: AppTypography.caption.copyWith(color: secondary),
    );
  }
}
