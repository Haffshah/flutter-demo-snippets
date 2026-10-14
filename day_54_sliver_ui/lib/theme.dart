import 'package:flutter/material.dart';

/// Color tokens for a yellow-on-dark theme (dark surfaces, one brand yellow, coral for "expired").
class Tokens {
  Tokens._();

  static const brandYellow = Color(0xffffd84d);
  static const bgDark = Color(0xff121212); // OLED-friendly background
  static const surfaceDark = Color(0xff1e1e1e);
  static const textPrimary = Color(0xffffffff);
  static const textSecondary = Color(0xffa5a5a5);
  static const textMuted = Color(0xff707070);

  static const statusActive = brandYellow;
  static const statusExpired = Color(0xffff6257);
  static const statusUsed = Color(0xff2ecc71);

  static ThemeData theme() => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(primary: brandYellow, surface: surfaceDark),
        appBarTheme: const AppBarTheme(backgroundColor: bgDark, elevation: 0, centerTitle: true),
      );
}
