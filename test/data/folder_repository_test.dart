import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/database/app_database.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';
import 'package:youtube_saver/data/folder/folder_repository.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/data/video/video_repository.dart';

FolderModel folder(String id, {String? parentId, String? name}) => FolderModel(
      id: id,
      parentId: parentId,
      name: name ?? id,
      position: 0,
      createdAt: DateTime(2026),
    );

List<String> ids(Result<List<FolderModel>> result) =>
    (result as Ok<List<FolderModel>>).value.map((f) => f.id).toList();

void main() {
  late AppDatabase db;
  late FolderRepository folders;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    folders = FolderRepository(db);
  });

  tearDown(() => db.close());

  test('createFolder appends at the end of its parent', () async {
    await folders.createFolder(folder('a'));
    await folders.createFolder(folder('b'));
    await folders.createFolder(folder('c', parentId: 'a'));

    expect(ids(await folders.getChildren(null)), ['a', 'b']);
    expect(ids(await folders.getChildren('a')), ['c']);
    final root = (await folders.getChildren(null) as Ok<List<FolderModel>>).value;
    expect(root.map((f) => f.position), [0, 1]);
  });

  test('createFolder with a missing parent returns Err', () async {
    final result = await folders.createFolder(folder('a', parentId: 'nope'));
    expect(result, isA<Err<void>>());
  });

  test('renameFolder changes the name, Err for an unknown id', () async {
    await folders.createFolder(folder('a'));

    expect(await folders.renameFolder('a', 'Music'), isA<Ok<void>>());
    final root = (await folders.getChildren(null) as Ok<List<FolderModel>>).value;
    expect(root.single.name, 'Music');
    expect(await folders.renameFolder('x', 'Y'), isA<Err<void>>());
  });

  test('deleteFolder removes subfolders and videos (cascade)', () async {
    final videos = VideoRepository(db);
    await folders.createFolder(folder('a'));
    await folders.createFolder(folder('b', parentId: 'a'));
    await videos.addVideo(VideoModel(
      id: 'v1',
      folderId: 'b',
      youtubeVideoId: 'abc',
      title: 't',
      channelName: 'c',
      thumbnailUrl: 'u',
      durationSeconds: null,
      position: 0,
      createdAt: DateTime(2026),
    ));

    expect(await folders.deleteFolder('a'), isA<Ok<void>>());

    expect(ids(await folders.getChildren('a')), isEmpty);
    expect(await db.select(db.folders).get(), isEmpty);
    expect(await db.select(db.videos).get(), isEmpty);
  });

  test('moveFolder puts the folder at the end of the new parent', () async {
    await folders.createFolder(folder('a'));
    await folders.createFolder(folder('b'));
    await folders.createFolder(folder('c', parentId: 'a'));

    await folders.moveFolder('b', 'a');

    expect(ids(await folders.getChildren(null)), ['a']);
    expect(ids(await folders.getChildren('a')), ['c', 'b']);
  });

  test('reorderFolders sets the sibling order', () async {
    await folders.createFolder(folder('a'));
    await folders.createFolder(folder('b'));
    await folders.createFolder(folder('c'));

    await folders.reorderFolders(null, ['c', 'a', 'b']);

    expect(ids(await folders.getChildren(null)), ['c', 'a', 'b']);
  });

  test('getPath returns folders from the root down', () async {
    await folders.createFolder(folder('a'));
    await folders.createFolder(folder('b', parentId: 'a'));
    await folders.createFolder(folder('c', parentId: 'b'));

    expect(ids(await folders.getPath('c')), ['a', 'b', 'c']);
    expect(await folders.getPath('nope'), isA<Err<List<FolderModel>>>());
  });

  test('watchChildren emits again when the children change', () async {
    final emissions = <List<String>>[];
    final sub = folders.watchChildren(null).listen((r) => emissions.add(ids(r)));

    await Future<void>.delayed(Duration.zero);
    await folders.createFolder(folder('a'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(emissions.first, isEmpty);
    expect(emissions.last, ['a']);
  });
}
