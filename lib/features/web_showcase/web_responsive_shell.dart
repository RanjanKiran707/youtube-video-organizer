import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_saver/features/web_showcase/desktop_showcase.dart';
import 'package:youtube_saver/features/web_showcase/mobile_web_landing.dart';

/// Responsive shell that hosts the app.
/// - On native mobile (Android/iOS): returns [child] unchanged.
/// - On Web on mobile/narrow screens (< 900px): displays the APK download landing page with app details.
/// - On Web on desktop screens (>= 900px): displays the split layout with left details pane and right phone demo.
class WebResponsiveShell extends StatelessWidget {
  final Widget child;

  const WebResponsiveShell({super.key, required this.child});

  static const double desktopBreakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < desktopBreakpoint) {
          return MobileWebLanding(previewChild: child);
        }
        return DesktopShowcase(child: child);
      },
    );
  }
}
