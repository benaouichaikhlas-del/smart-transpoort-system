import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6aabf0);
  static const Color secondary = Color(0xFF4dbf9e);
  static const Color background = Color(0xFF1E1E2E);
  static const Color surface = Color(0xFF2A2A3E);
  static const Color textPrimary = Colors.white;
  static const Color textSecond = Colors.white54;
  static const Color error = Color(0xFFf07060);
  static const Color warning = Color(0xFFf0c060);

  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: background,
        useMaterial3: true,
      );

  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary),
      ),
    );
  }

  static ButtonStyle primaryButton({Color? color}) => ElevatedButton.styleFrom(
        backgroundColor: color ?? primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
