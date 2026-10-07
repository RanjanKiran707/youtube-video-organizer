import 'package:flutter/material.dart';

/// Monochrome with one red accent, light and dark (see project_spec/mockup.html).
class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFE5322D),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFE5322D),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF111111),
      onSurfaceVariant: Color(0xFF8A8A86),
      surfaceContainerHighest: Color(0xFFF6F6F5),
      outlineVariant: Color(0xFFE8E8E5),
    ),
  );

  static final ThemeData dark = _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFF5A54),
      onPrimary: Color(0xFF101010),
      secondary: Color(0xFFFF5A54),
      onSecondary: Color(0xFF101010),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      surface: Color(0xFF101010),
      onSurface: Color(0xFFF2F2F0),
      onSurfaceVariant: Color(0xFF8C8C88),
      surfaceContainerHighest: Color(0xFF1A1A1A),
      outlineVariant: Color(0xFF262626),
    ),
  );

  static ThemeData _build(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      shape: const CircleBorder(),
    ),
  );
}
