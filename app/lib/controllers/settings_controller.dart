import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  // Color constants for easy reference across the app
  static const Color accentColor = Color(0xFFD17A4A);

  // Dark theme
  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    barBackgroundColor: Colors.transparent,
    primaryColor: accentColor,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(color: Colors.white),
    ),
  );

  // Light theme
  static const CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    barBackgroundColor: Colors.transparent,
    primaryColor: accentColor,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(color: Colors.black87),
    ),
  );

  // Observable theme
  final Rx<CupertinoThemeData> currentTheme = darkTheme.obs;

  // Computed properties for easy access
  bool get isDarkMode => currentTheme.value.brightness == Brightness.dark;

  Color get backgroundColor =>
      isDarkMode ? Colors.black : const Color(0xFFF5F5F5);
  Color get surfaceColor => isDarkMode ? const Color(0xFF18181B) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get subtextColor =>
      isDarkMode ? const Color(0xFF71717A) : Colors.black54;
  Color get borderColor =>
      isDarkMode ? const Color(0xFF27272A) : const Color(0xFFE5E5E5);

  // Body view settings
  final isMale = true.obs;
  final isFrontView = true.obs;

  // Toggle gender
  void toggleGender() => isMale.value = !isMale.value;

  // Toggle view (front/back)
  void toggleView() => isFrontView.value = !isFrontView.value;

  // Toggle theme
  void toggleTheme() {
    if (currentTheme.value.brightness == Brightness.dark) {
      currentTheme.value = lightTheme;
    } else {
      currentTheme.value = darkTheme;
    }
  }

  // Explicitly set theme
  void setTheme(bool isDark) {
    currentTheme.value = isDark ? darkTheme : lightTheme;
  }
}
