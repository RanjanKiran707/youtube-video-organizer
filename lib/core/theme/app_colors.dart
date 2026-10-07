import 'package:flutter/material.dart';

/// The colour tokens of project_spec/mockup.html (`--bg`, `--surface`, ...).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color text;
  final Color muted;
  final Color line;
  final Color accent;
  final Color onAccent;
  final Color thumb;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.thumb,
  });

  static const light = AppColors(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF6F6F5),
    text: Color(0xFF111111),
    muted: Color(0xFF8A8A86),
    line: Color(0xFFE8E8E5),
    accent: Color(0xFFE5322D),
    onAccent: Color(0xFFFFFFFF),
    thumb: Color(0xFFD9D9D5),
  );

  static const dark = AppColors(
    bg: Color(0xFF101010),
    surface: Color(0xFF1A1A1A),
    text: Color(0xFFF2F2F0),
    muted: Color(0xFF8C8C88),
    line: Color(0xFF262626),
    accent: Color(0xFFFF5A54),
    onAccent: Color(0xFF101010),
    thumb: Color(0xFF2C2C2C),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? text,
    Color? muted,
    Color? line,
    Color? accent,
    Color? onAccent,
    Color? thumb,
  }) => AppColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    thumb: thumb ?? this.thumb,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      thumb: Color.lerp(thumb, other.thumb, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
