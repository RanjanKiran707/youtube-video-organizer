import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_saver/features/web_showcase/mobile_web_landing.dart';

void main() {
  testWidgets('MobileWebLanding displays app branding, headline, features, and download CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MobileWebLanding(),
      ),
    );
    await tester.pump();

    // Verify app title and release badge
    expect(find.text('YT Playlist'), findsWidgets);
    expect(find.textContaining('v1.0.0 Release'), findsOneWidget);

    // Verify headline and description from left pane
    expect(find.textContaining('Organize YouTube'), findsOneWidget);
    expect(find.textContaining('Zero distractions'), findsOneWidget);
    expect(
      find.textContaining('Save YouTube videos into custom nested folders'),
      findsOneWidget,
    );

    // Verify download buttons
    expect(find.text('Download APK (v1.0.0)'), findsOneWidget);
    expect(find.text('View GitHub Release Notes'), findsOneWidget);

    // Verify features from left pane
    expect(find.text('Custom Nested Folders'), findsOneWidget);
    expect(find.text('Continuous Playback'), findsOneWidget);
    expect(find.text('Distraction-Free Player'), findsOneWidget);
    expect(find.text('Local-First SQLite Storage'), findsOneWidget);

    // Verify how it works steps
    expect(find.text('Share from YouTube'), findsOneWidget);
    expect(find.text('Pick your folder'), findsOneWidget);
    expect(find.text('Watch distraction-free'), findsOneWidget);
  });

  testWidgets('MobileWebLanding allows toggling interactive web preview if provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MobileWebLanding(
          previewChild: Text('My Mock Demo View'),
        ),
      ),
    );
    await tester.pump();

    // Initial state does not show preview child
    expect(find.text('My Mock Demo View'), findsNothing);
    final previewBtn = find.text('Preview');
    await tester.ensureVisible(previewBtn);
    await tester.pumpAndSettle();

    // Tap preview button
    await tester.tap(previewBtn);
    await tester.pumpAndSettle();

    // Now preview is visible
    expect(find.text('My Mock Demo View'), findsOneWidget);
    expect(find.text('Interactive Web Preview'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Returns to landing page
    expect(find.text('My Mock Demo View'), findsNothing);
    expect(find.text('Download APK (v1.0.0)'), findsOneWidget);
  });
}
