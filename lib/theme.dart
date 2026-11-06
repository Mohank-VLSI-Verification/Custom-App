import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0F172A);
  static const appBarScrolled = Color(0xFF1C2434);
  static const card = Color(0xFF1E293B);
  static const tile = Color(0xFF334155);
  static const grid = Color(0xFF334155);
  static const text = Color(0xFFF1F5F9);
  static const muted = Color(0xFF94A3B8);
  static const faint = Color(0xFF64748B);
  static const weekendDate = Color(0xFFB4BCC8);
  static const outsideDate = Color(0xFF475569);
  static const punchIn = Color(0xFF4CAF50);
  static const punchOut = Color(0xFFE53935);
  static const hoursGreen = Color(0xFF6EE7B7);
  static const payday = Color(0xFF4CAF50);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1),
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.scrolledUnder)
            ? AppColors.appBarScrolled
            : AppColors.bg,
      ),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
