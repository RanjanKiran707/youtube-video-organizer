import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/features/app/app.dart';
import 'package:youtube_saver/features/app/share_source.dart';
import 'package:youtube_saver/features/folder_picker/folder_picker_view.dart';
import 'package:youtube_saver/features/shared/widgets/folder_tile.dart';

import 'fakes/fake_folder_repository.dart';
import 'fakes/fake_video_metadata_repository.dart';
import 'fakes/fake_video_repository.dart';

void main() {
  late FakeFolderRepository folders;
  late FakeVideoRepository videos;
  late FakeVideoMetadataRepository metadata;

  // The fakes are created inside the test body, so their streams belong to the
  // test's fake-async zone and `pump` can run their callbacks.
  void widgetTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      folders = FakeFolderRepository();
      videos = FakeVideoRepository();
      metadata = FakeVideoMetadataRepository();
      await AppDependencies.init(
        folderRepository: folders,
        videoRepository: videos,
        metadataRepository: metadata,
      );
      await body(tester);
    });
  }

  Future<void> pumpApp(WidgetTester tester, {ShareSource? shares}) async {
    await tester.pumpWidget(
      YoutubeSaverApp(shareSource: shares ?? const NoShareSource()),
    );
    await tester.pump();
    await tester.pump();
  }

  widgetTest('an empty library shows the hint', (tester) async {
    await pumpApp(tester);

    expect(find.textContaining('Nothing here yet'), findsOneWidget);
  });

  widgetTest('the library lists folders with counts, then videos', (
    tester,
  ) async {
    folders.add('music', null, 'Music');
    videos.add('m1', 'music');
    videos.add('m2', 'music');
    videos.add('root', null, title: 'Root video');

    await pumpApp(tester);

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('2 videos'), findsOneWidget);
    expect(find.text('Root video'), findsOneWidget);
    expect(find.text('Play all'), findsOneWidget);
  });

  widgetTest('New folder creates a folder that then shows in the list', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Podcasts');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(folders.folders.single.name, 'Podcasts');
    expect(find.text('Podcasts'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
  });

  widgetTest('New folder shows the error and stays open for a bad name', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name.'), findsOneWidget);
    expect(folders.folders, isEmpty);
  });

  widgetTest('tapping a folder opens it', (tester) async {
    folders.add('music', null, 'Music');
    videos.add('m1', 'music', title: 'Song one');

    await pumpApp(tester);
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();

    expect(find.text('Song one'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  widgetTest('a shared YouTube link opens the picker and saves to a folder', (
    tester,
  ) async {
    folders.add('music', null, 'Music');
    final shares = _FakeShares('Watch https://youtu.be/dQw4w9WgXcQ');

    await pumpApp(tester, shares: shares);
    await tester.pumpAndSettle();

    expect(find.text('Save video'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(FolderPickerView),
        matching: find.text('Music'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to Music'));
    await tester.pumpAndSettle();

    final saved = videos.videos.single;
    expect(saved.folderId, 'music');
    expect(saved.youtubeVideoId, 'dQw4w9WgXcQ');
    expect(find.text('Save video'), findsNothing);
    expect(find.text('Saved.'), findsOneWidget);
  });

  widgetTest('a shared link that is not a video is rejected with a message', (
    tester,
  ) async {
    await pumpApp(tester, shares: _FakeShares('https://example.com'));
    await tester.pumpAndSettle();

    expect(find.text('Save video'), findsNothing);
    expect(find.textContaining("isn't a link"), findsOneWidget);
  });

  test('countLabel', () {
    expect(countLabel(0, 0), 'Empty');
    expect(countLabel(1, 0), '1 video');
    expect(countLabel(12, 2), '12 videos · 2 folders');
  });
}

class _FakeShares implements ShareSource {
  final String text;
  _FakeShares(this.text);

  @override
  Future<String?> initialText() async => text;

  @override
  Stream<String> texts() => const Stream.empty();
}
