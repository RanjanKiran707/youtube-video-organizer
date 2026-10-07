import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/database/app_database.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';
import 'package:youtube_saver/data/folder/folder_repository.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/data/video/video_repository.dart';

VideoModel video(String id, {String? folderId, String youtubeId = 'abc'}) =>
    VideoModel(
      id: id,
      folderId: folderId,
      youtubeVideoId: youtubeId,
      title: 'title $id',
      channelName: 'channel',
      thumbnailUrl: 'https://img/$id.jpg',
      durationSeconds: 60,
      position: 0,
      createdAt: DateTime(2026),
    );

List<String> ids(Result<List<VideoModel>> result) =>
    (result as Ok<List<VideoModel>>).value.map((v) => v.id).toList();

void main() {
  late AppDatabase db;
  late VideoRepository videos;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    videos = VideoRepository(db);
    final folders = FolderRepository(db);
    for (final id in ['f1', 'f2']) {
      await folders.createFolder(FolderModel(
        id: id,
        parentId: null,
        name: id,
        position: 0,
        createdAt: DateTime(2026),
      ));
    }
  });

  tearDown(() => db.close());

  test('addVideo appends in play order within its folder', () async {
    await videos.addVideo(video('a', folderId: 'f1'));
    await videos.addVideo(video('b', folderId: 'f1'));
    await videos.addVideo(video('c', folderId: 'f2'));

    expect(ids(await videos.getVideos('f1')), ['a', 'b']);
    expect(ids(await videos.getVideos('f2')), ['c']);
  });

  test('the same YouTube video can be saved in several folders', () async {
    expect(await videos.addVideo(video('a', folderId: 'f1')), isA<Ok<void>>());
    expect(await videos.addVideo(video('b', folderId: 'f2')), isA<Ok<void>>());
    expect(await videos.addVideo(video('c', folderId: 'f1')), isA<Ok<void>>());
  });

  test('addVideo to a missing folder returns Err', () async {
    final result = await videos.addVideo(video('a', folderId: 'nope'));
    expect(result, isA<Err<void>>());
  });

  test('videos can live at the root', () async {
    await videos.addVideo(video('a'));
    expect(ids(await videos.getVideos(null)), ['a']);
  });

  test('renameVideo and deleteVideo, Err for an unknown id', () async {
    await videos.addVideo(video('a', folderId: 'f1'));

    expect(await videos.renameVideo('a', 'New'), isA<Ok<void>>());
    final list = (await videos.getVideos('f1') as Ok<List<VideoModel>>).value;
    expect(list.single.title, 'New');

    expect(await videos.deleteVideo('a'), isA<Ok<void>>());
    expect(ids(await videos.getVideos('f1')), isEmpty);
    expect(await videos.deleteVideo('a'), isA<Err<void>>());
    expect(await videos.renameVideo('a', 'x'), isA<Err<void>>());
  });

  test('moveVideo puts the video at the end of the new folder', () async {
    await videos.addVideo(video('a', folderId: 'f1'));
    await videos.addVideo(video('b', folderId: 'f2'));

    await videos.moveVideo('a', 'f2');

    expect(ids(await videos.getVideos('f1')), isEmpty);
    expect(ids(await videos.getVideos('f2')), ['b', 'a']);
  });

  test('reorderVideos sets the play order', () async {
    await videos.addVideo(video('a', folderId: 'f1'));
    await videos.addVideo(video('b', folderId: 'f1'));
    await videos.addVideo(video('c', folderId: 'f1'));

    await videos.reorderVideos('f1', ['c', 'a', 'b']);

    expect(ids(await videos.getVideos('f1')), ['c', 'a', 'b']);
  });

  test('watchVideos emits again when the videos change', () async {
    final emissions = <List<String>>[];
    final sub = videos.watchVideos('f1').listen((r) => emissions.add(ids(r)));

    await Future<void>.delayed(Duration.zero);
    await videos.addVideo(video('a', folderId: 'f1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(emissions.first, isEmpty);
    expect(emissions.last, ['a']);
  });
}
