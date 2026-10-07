import 'package:flutter/material.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';

/// The mockup's `.btn`: a pill with a 1px line border. `primary` fills it with
/// the accent colour; `block` makes it full width with 14px corners.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool block;

  /// For buttons on the black player area (white text and border).
  final bool onDark;
  final IconData? icon;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.block = false,
    this.onDark = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color foreground = primary
        ? c.onAccent
        : onDark
        ? Colors.white
        : c.text;
    final Color fill = primary ? c.accent : Colors.transparent;
    final Color border = primary
        ? c.accent
        : onDark
        ? const Color(0x66FFFFFF)
        : c.line;
    final radius = BorderRadius.circular(block ? 14 : 999);

    final content = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: foreground,
              fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: block
                ? const EdgeInsets.all(14)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: content,
          ),
        ),
      ),
    );
  }
}
