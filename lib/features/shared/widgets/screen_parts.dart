import 'package:flutter/material.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';
import 'package:youtube_saver/features/shared/widgets/app_icon.dart';

/// The mockup's `.bar`: optional crumb, 24px title, optional action row.
class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? crumb;
  final Widget? actions;

  const ScreenHeader({
    super.key,
    required this.title,
    this.crumb,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // Full width, so it stays left-aligned inside a centred Column too.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (crumb != null) crumb!,
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.48,
                color: c.text,
              ),
            ),
          ),
          if (actions != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: actions),
        ],
      ),
    );
  }
}

/// The mockup's `.fab`: 52px accent circle with a light "+".
class AppFab extends StatelessWidget {
  final VoidCallback? onPressed;
  const AppFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      button: true,
      label: 'New folder',
      child: Material(
        color: c.accent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('new_folder_fab'),
          onTap: onPressed,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w300,
                  color: c.onAccent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The mockup's `.empty`: icon tile, 16px heading, muted text.
class EmptyState extends StatelessWidget {
  final String heading;
  final String text;

  const EmptyState({super.key, required this.heading, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: AppIcon(AppIconData.share, size: 26, color: c.muted),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              heading,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
