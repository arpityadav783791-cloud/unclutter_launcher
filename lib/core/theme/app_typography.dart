import 'package:flutter/material.dart';

/// Centralized typography definitions for Unclutter Launcher.
/// Consistent scale, line heights, letter spacing, and contrast.
class AppTypography {
  AppTypography._();

  // Font family fallback: default clean system sans-serif font
  static const String? fontFamily = null;

  // ── High Contrast Display / Clock ─────────────────────────────
  static const TextStyle clock = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    height: 1.1,
  );

  static const TextStyle clockDate = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.25,
  );

  // ── Titles & Screen Headers ───────────────────────────────────
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.2,
  );

  // ── App Drawer & List Tiles ───────────────────────────────────
  static const TextStyle appTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.25,
  );

  static const TextStyle appTitleBold = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    height: 1.25,
  );

  static const TextStyle favoriteStar = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // ── Body & Descriptions ───────────────────────────────────────
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.2,
  );

  // ── Interactive / Buttons ─────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
  );

  static const TextStyle searchInput = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.25,
  );
}
