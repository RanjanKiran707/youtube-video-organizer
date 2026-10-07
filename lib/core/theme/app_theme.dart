import 'package:flutter/material.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';

/// Monochrome with one red accent, light and dark (see project_spec/mockup.html).
class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(Brightness.light, AppColors.light);
  static final ThemeData dark = _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.accent,
      onError: c.onAccent,
      surface: c.bg,
      onSurface: c.text,
      onSurfaceVariant: c.muted,
      surfaceContainerHighest: c.surface,
      outlineVariant: c.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [c],
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.line,
      // The mockup is 14px / 1.4, in the system font.
      textTheme: Typography.material2021(platform: TargetPlatform.android).black
          .apply(fontSizeFactor: 1, bodyColor: c.text, displayColor: c.text)
          .copyWith(
            bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: c.text),
          ),
      splashFactory: InkRipple.splashFactory,
      popupMenuTheme: PopupMenuThemeData(
        color: c.bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
        ),
        textStyle: TextStyle(fontSize: 14, color: c.text),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: TextStyle(color: c.bg, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
