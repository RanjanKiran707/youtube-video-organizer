import 'package:flutter/material.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';

/// The mockup's `.item`: 12px / 20px padding, 14px gap, name over a muted line.
class AppRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// The row that is playing: surface background, accent name.
  final bool highlighted;

  /// Show the name in the accent colour and without a subtitle ("New folder").
  final bool link;

  const AppRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.highlighted = false,
    this.link = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Material(
      color: highlighted ? c.surface : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: highlighted || link ? c.accent : c.text,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: c.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 14), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Puts the mockup's 1px line between adjacent rows (`.item + .item`).
List<Widget> dividedRows(BuildContext context, List<Widget> rows) {
  final line = context.colors.line;
  return [
    for (var i = 0; i < rows.length; i++) ...[
      if (i > 0) Divider(height: 1, thickness: 1, color: line),
      rows[i],
    ],
  ];
}

/// The mockup's `.section`: small uppercase muted label.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          height: 1.4,
          letterSpacing: 11 * 0.08,
          color: context.colors.muted,
        ),
      ),
    );
  }
}

/// The muted "⋮" or "›" at the end of a row.
class RowGlyph extends StatelessWidget {
  final String glyph;
  const RowGlyph(this.glyph, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      glyph,
      style: TextStyle(color: context.colors.muted, letterSpacing: 2),
    );
  }
}

/// The mockup's "⋮", drawn as three dots so it does not depend on a font.
class MoreDots extends StatelessWidget {
  const MoreDots({super.key});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: context.colors.muted,
        shape: BoxShape.circle,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(height: 3),
        dot,
        const SizedBox(height: 3),
        dot,
      ],
    );
  }
}
