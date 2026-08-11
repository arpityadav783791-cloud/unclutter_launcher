import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _lightTextColor = Colors.black;
  static const _darkTextColor = Colors.white;

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    useMaterial3: true,

    colorScheme: const ColorScheme.light(
      primary: _lightTextColor,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: _lightTextColor,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontSize: 20,
        color: _lightTextColor,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: 18,
        color: _lightTextColor,
        fontWeight: FontWeight.w400,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    useMaterial3: true,

    colorScheme: const ColorScheme.dark(
      primary: _darkTextColor,
      onPrimary: Colors.black,
      surface: Colors.black,
      onSurface: _darkTextColor,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontSize: 20,
        color: _darkTextColor,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: 18,
        color: _darkTextColor,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}
