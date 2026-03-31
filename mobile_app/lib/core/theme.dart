import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF1565C0);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _primaryColor,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(centerTitle: true),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _primaryColor,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(centerTitle: true),
      );
}
