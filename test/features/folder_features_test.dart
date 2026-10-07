import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/features/folder_picker/folder_picker_view_model.dart';
import 'package:youtube_saver/features/library/library_view_model.dart';
import 'package:youtube_saver/features/new_folder/new_folder_view_model.dart';
import 'package:youtube_saver/features/shared/folder_browser_controller.dart';

import '../fakes/fake_folder_repository.dart';
import '../fakes/fake_video_metadata_repository.dart';
import '../fakes/fake_video_repository.dart';

void main() {
  late FakeFolderRepository folders;
  late FakeVideoRepository videos;

  setUp(() async {
    folders = FakeFolderRepository();
    videos = FakeVideoRepository();
    await AppDependencies.init(
      folderRepository: folders,
      videoRepository: videos,
      metadataRepository: FakeVideoMetadataRepository(),
    );
  });

  group('NewFolderViewModel', () {
    NewFolderViewModel create({String? parent}) => NewFolderViewModel(
      bundle: NewFolderBundle(parentId: parent),
      createFolder: AppDependencies.instance.createFolder,
    );

    test('goes Idle -> Loading -> Loaded and creates the folder', () async {
      final vm = create();
      final seen = <Type>[vm.createState.value.runtimeType];
      vm.createState.addListener(
        () => seen.add(vm.createState.value.runtimeType),
      );

      await vm.onCreate('Music');

      expect(seen, [
        ViewStateIdle<void>,
        ViewStateLoading<void>,
        ViewStateLoaded<void>,
      ]);
      expect(folders.folders.single.name, 'Music');
      vm.dispose();
    });

    test('an empty name is an Error state and creates nothing', () async {
      final vm = create();

      await vm.onCreate('  ');

      final state = vm.createState.value as ViewStateError<void>;
      expect(state.failure, isA<ValidationFailure>());
      expect(folders.folders, isEmpty);
      vm.dispose();
    });

    test('a second call while Loading is ignored', () async {
      final vm = create();

      final first = vm.onCreate('Music');
      final second = vm.onCreate('Music');
      await Future.wait([first, second]);

      expect(folders.folders, hasLength(1));
      vm.dispose();
    });
  });

  group('FolderBrowserController', () {
    FolderBrowserController browse(String? start) => FolderBrowserController(
      listContents: AppDependencies.instance.listFolderContents,
      getPath: AppDependencies.instance.getFolderPath,
      initialFolderId: start,
    );

    test('loads the folder and updates live', () async {
      folders.add('a', null, 'A');
      final browser = browse(null);
      await pumpEventQueue();

      var data =
          (browser.state.value as ViewStateLoaded<FolderBrowserData>).data;
      expect(data.contents.folders.map((f) => f.name), ['A']);

      folders.add('b', null, 'B');
      await pumpEventQueue();

      data = (browser.state.value as ViewStateLoaded<FolderBrowserData>).data;
      expect(data.contents.folders.map((f) => f.name), ['A', 'B']);
      browser.dispose();
    });

    test('open moves to another folder and reports its path', () async {
      folders.add('a', null, 'A');
      folders.add('b', 'a', 'B');
      final browser = browse(null);
      await pumpEventQueue();

      await browser.open('b');
      await pumpEventQueue();

      final data =
          (browser.state.value as ViewStateLoaded<FolderBrowserData>).data;
      expect(data.path.map((f) => f.id), ['a', 'b']);
      expect(browser.folderId, 'b');
      browser.dispose();
    });

    test('an unknown folder is an Error state', () async {
      final browser = browse('missing');
      await pumpEventQueue();

      expect(browser.state.value, isA<ViewStateError<FolderBrowserData>>());
      browser.dispose();
    });

    test('dispose cancels the subscription, and does not hang', () async {
      final browser = browse(null);
      await pumpEventQueue();

      browser.dispose();
      folders.add('late', null, 'Late'); // must not reach a disposed notifier
      await pumpEventQueue();
    });
  });

  group('FolderPickerViewModel', () {
    FolderPickerViewModel create(
      Future<Result<void>> Function(String?) onConfirm, {
      String? start,
    }) => FolderPickerViewModel(
      bundle: FolderPickerBundle(
        title: 'Save',
        confirmVerb: 'Save',
        initialFolderId: start,
        onConfirm: onConfirm,
      ),
      listFolderContents: AppDependencies.instance.listFolderContents,
      getFolderPath: AppDependencies.instance.getFolderPath,
    );

    test('navigates into a folder and back up', () async {
      folders.add('a', null, 'A');
      folders.add('b', 'a', 'B');
      final vm = create((_) async => const Ok(null));
      await pumpEventQueue();

      vm.open('b');
      await pumpEventQueue();
      expect(vm.browser.folderId, 'b');

      vm.up();
      await pumpEventQueue();
      expect(vm.browser.folderId, 'a');

      vm.up();
      await pumpEventQueue();
      expect(vm.atRoot, isTrue);
      vm.dispose();
    });

    test('confirm passes the open folder and finishes Loaded', () async {
      folders.add('a', null, 'A');
      String? confirmedWith = 'unset';
      final vm = create((id) async {
        confirmedWith = id;
        return const Ok(null);
      }, start: 'a');
      await pumpEventQueue();

      await vm.confirm();

      expect(confirmedWith, 'a');
      expect(vm.confirmState.value, isA<ViewStateLoaded<void>>());
      vm.dispose();
    });

    test('a failed confirm is an Error state, and can be retried', () async {
      var calls = 0;
      final vm = create((_) async {
        calls++;
        return calls == 1 ? const Err(StorageFailure('boom')) : const Ok(null);
      });
      await pumpEventQueue();

      await vm.confirm();
      expect(vm.confirmState.value, isA<ViewStateError<void>>());

      await vm.confirm();
      expect(vm.confirmState.value, isA<ViewStateLoaded<void>>());
      vm.dispose();
    });

    test(
      'a second confirm while Loading is ignored, and navigation is blocked',
      () async {
        folders.add('a', null, 'A');
        final gate = Completer<Result<void>>();
        var calls = 0;
        final vm = create((_) {
          calls++;
          return gate.future;
        });
        await pumpEventQueue();

        final first = vm.confirm();
        await vm.confirm();
        vm.open('a');
        expect(vm.browser.folderId, isNull);

        gate.complete(const Ok(null));
        await first;
        expect(calls, 1);
        vm.dispose();
      },
    );
  });

  group('LibraryViewModel', () {
    LibraryViewModel create({String? folderId}) {
      final deps = AppDependencies.instance;
      return LibraryViewModel(
        bundle: LibraryBundle(folderId: folderId),
        listFolderContents: deps.listFolderContents,
        getFolderPath: deps.getFolderPath,
        renameFolder: deps.renameFolder,
        renameVideo: deps.renameVideo,
        deleteFolder: deps.deleteFolder,
        deleteVideo: deps.deleteVideo,
        moveFolder: deps.moveFolder,
        moveVideo: deps.moveVideo,
      );
    }

    test(
      'delete goes Idle -> Loading -> Loaded and removes the video',
      () async {
        videos.add('v', null);
        final vm = create();
        final seen = <Type>[vm.actionState.value.runtimeType];
        vm.actionState.addListener(
          () => seen.add(vm.actionState.value.runtimeType),
        );

        await vm.deleteVideo('v');

        expect(seen, [
          ViewStateIdle<void>,
          ViewStateLoading<void>,
          ViewStateLoaded<void>,
        ]);
        expect(videos.videos, isEmpty);
        vm.dispose();
      },
    );

    test('a rename that clashes is an Error state', () async {
      folders.add('a', null, 'Music');
      folders.add('b', null, 'Talks');
      final vm = create();

      await vm.renameFolder('b', 'music');

      final state = vm.actionState.value as ViewStateError<void>;
      expect((state.failure as ValidationFailure).message, 'name_taken');
      vm.dispose();
    });

    test('a second action while Loading is ignored', () async {
      videos.add('v', null);
      final vm = create();

      final first = vm.deleteVideo('v');
      final second = vm.deleteVideo('v'); // would be video_not_found if it ran
      await Future.wait([first, second]);

      expect(vm.actionState.value, isA<ViewStateLoaded<void>>());
      vm.dispose();
    });

    test('moveFolder returns the use case result', () async {
      folders.add('a', null, 'A');

      final result = await create().moveFolder('a', 'a');

      expect(result, isA<Err<void>>());
    });
  });
}
