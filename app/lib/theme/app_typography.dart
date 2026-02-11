import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

/// Centralized typography for consistent Apple-style fonts
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // Font weights following Apple HIG
  static const fontWeightLight = FontWeight.w300;
  static const fontWeightRegular = FontWeight.w400;
  static const fontWeightMedium = FontWeight.w500;
  static const fontWeightSemibold = FontWeight.w600;
  static const fontWeightBold = FontWeight.w700;

  // ----- DARK THEME TEXT STYLES -----

  /// Large title (e.g., page headers)
  static TextStyle titleLarge(bool isDark) => TextStyle(
    fontSize: 28,
    fontWeight: fontWeightBold,
    letterSpacing: -0.5,
    color: isDark ? Colors.white : Colors.black87,
    decoration: TextDecoration.none,
  );

  /// Section headers
  static TextStyle titleMedium(bool isDark) => TextStyle(
    fontSize: 20,
    fontWeight: fontWeightSemibold,
    letterSpacing: -0.3,
    color: isDark ? Colors.white : Colors.black87,
    decoration: TextDecoration.none,
  );

  /// Subsection headers
  static TextStyle titleSmall(bool isDark) => TextStyle(
    fontSize: 17,
    fontWeight: fontWeightSemibold,
    letterSpacing: -0.2,
    color: isDark ? Colors.white : Colors.black87,
    decoration: TextDecoration.none,
  );

  /// Body text
  static TextStyle body(bool isDark) => TextStyle(
    fontSize: 15,
    fontWeight: fontWeightRegular,
    letterSpacing: -0.1,
    color: isDark ? Colors.white : Colors.black87,
    decoration: TextDecoration.none,
  );

  /// Secondary/muted body text
  static TextStyle bodySecondary(bool isDark) => TextStyle(
    fontSize: 15,
    fontWeight: fontWeightRegular,
    letterSpacing: -0.1,
    color: isDark ? const Color(0xFFA1A1AA) : Colors.black54,
    decoration: TextDecoration.none,
  );

  /// Small caption text
  static TextStyle caption(bool isDark) => TextStyle(
    fontSize: 10,
    fontWeight: fontWeightRegular,
    letterSpacing: 0,
    color: isDark ? const Color(0xFF71717A) : Colors.black45,
    decoration: TextDecoration.none,
  );

  /// Label text (e.g., form labels, section labels)
  static TextStyle label(bool isDark) => TextStyle(
    fontSize: 18,
    fontWeight: fontWeightMedium,
    letterSpacing: 0,
    color: isDark ? const Color(0xFFA1A1AA) : Colors.black54,
    decoration: TextDecoration.none,
  );

  /// Accent text (using the app's orange accent)
  static const accentColor = Color(0xFFD17A4A);

  static TextStyle accent({double fontSize = 14}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeightSemibold,
    letterSpacing: -0.1,
    color: accentColor,
    decoration: TextDecoration.none,
  );

  /// Button text
  static TextStyle button(bool isDark) => TextStyle(
    fontSize: 15,
    fontWeight: fontWeightMedium,
    letterSpacing: -0.1,
    color: isDark ? Colors.white : Colors.black87,
    decoration: TextDecoration.none,
  );
}

/// Spacing constants for consistent Apple-style layout
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
