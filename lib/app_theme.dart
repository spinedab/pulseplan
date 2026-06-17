import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xff0f766e);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        primary: seed,
        secondary: const Color(0xffc2410c),
        tertiary: const Color(0xffbe185d),
        surface: const Color(0xfffbfbf8),
      ),
      scaffoldBackgroundColor: const Color(0xfff5f5ef),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        primary: const Color(0xff2dd4bf),
        secondary: const Color(0xfff97316),
        tertiary: const Color(0xfff472b6),
        surface: const Color(0xff1c1917),
      ),
      scaffoldBackgroundColor: const Color(0xff0c0a09),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  static Color surfaceCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff292524)
        : Colors.white;
  }
}