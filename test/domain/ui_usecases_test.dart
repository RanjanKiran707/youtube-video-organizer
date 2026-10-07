import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_play_queue/get_play_queue_usecase.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_usecase.dart';

import '../fakes/fake_folder_repository.dart';
import '../fakes/fake_video_repository.dart';

void main() {
  late FakeFolderRepository folders;
  late FakeVideoRepository videos;

  setUp(() {
    folders = FakeFolderRepository();
    videos = FakeVideoRepository();
  });

  group('GetFolderPathUsecase', () {
    test('the library root has an empty path', () async {
      final result = await GetFolderPathUsecase(folders)(null);

      expect((result as Ok).value, isEmpty);
    });

    test('returns root first, the folder last', () async {
      folders.add('a', null, 'A');
      folders.add('b', 'a', 'B');

      final result = await GetFolderPathUsecase(folders)('b');

      expect((result as Ok).value.map((f) => f.id), ['a', 'b']);
    });
  });

  group('GetPlayQueueUsecase', () {
    test('holds only the direct videos of the folder', () async {
      videos.add('a', 'f');
      videos.add('b', 'f');
      videos.add('deeper', 'sub');

      final result = await GetPlayQueueUsecase(videos)('f');

      final queue = (result as Ok).value;
      expect(queue.videos.map((v) => v.id), ['a', 'b']);
    });

    test('indexOf finds the start video, and falls back to the first', () async {
      videos.add('a', 'f');
      videos.add('b', 'f');

      final queue = ((await GetPlayQueueUsecase(videos)('f')) as Ok).value;

      expect(queue.indexOf('b'), 1);
      expect(queue.indexOf('missing'), 0);
      expect(queue.indexOf(null), 0);
    });

    test('a storage failure is an Err', () async {
      videos.failWith = const StorageFailure('boom');

      final result = await GetPlayQueueUsecase(videos)('f');

      expect(result, isA<Err>());
    });
  });

  group('ListFolderContentsUsecase', () {
    ListFolderContentsReturnModel value(Result<ListFolderContentsReturnModel> r) =>
        (r as Ok<ListFolderContentsReturnModel>).value;

    test('lists subfolders with counts, then the folder videos', () async {
      folders.add('music', null, 'Music');
      folders.add('rock', 'music', 'Rock');
      videos.add('m1', 'music');
      videos.add('m2', 'music');
      videos.add('root', null);

      final first =
          await ListFolderContentsUsecase(folders, videos)(null).first;

      final model = value(first);
      expect(model.folders.single.name, 'Music');
      expect(model.folders.single.videoCount, 2);
      expect(model.folders.single.folderCount, 1);
      expect(model.videos.map((v) => v.id), ['root']);
      expect(model.isEmpty, isFalse);
    });

    test('an empty folder is empty', () async {
      final first =
          await ListFolderContentsUsecase(folders, videos)('none').first;

      expect(value(first).isEmpty, isTrue);
    });

    test('emits again when a video is added, and cancelling does not hang',
        () async {
      final results = <ListFolderContentsReturnModel>[];
      final sub = ListFolderContentsUsecase(folders, videos)('f')
          .listen((r) => results.add(value(r)));

      await pumpEventQueue();
      videos.add('a', 'f');
      await pumpEventQueue();

      expect(results.last.videos.map((v) => v.id), ['a']);
      await sub.cancel().timeout(const Duration(seconds: 2));
    });

    test('a failure from either repository is emitted as Err', () async {
      videos.failWith = const StorageFailure('boom');

      final first =
          await ListFolderContentsUsecase(folders, videos)(null).first;

      expect(first, isA<Err>());
    });
  });
}
