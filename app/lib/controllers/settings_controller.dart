import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  // Define themes
  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    barBackgroundColor: Colors.black,
    primaryColor: Color(0xFFD17A4A), // accentColor from App design
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(color: Colors.white),
    ),
  );

  static const CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: CupertinoColors.systemBackground,
    barBackgroundColor: CupertinoColors.systemBackground,
    primaryColor: Color(0xFFD17A4A),
  );

  // Observable theme
  final Rx<CupertinoThemeData> currentTheme = darkTheme.obs;

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
