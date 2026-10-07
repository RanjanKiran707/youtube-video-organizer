import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_model.dart';
import 'package:youtube_saver/domain/use_cases/business/rename_video/rename_video_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/reorder_videos/reorder_videos_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/save_shared_video_argument_model.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/save_shared_video_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/youtube_url_parser.dart';

import '../fakes/fake_video_metadata_repository.dart';
import '../fakes/fake_video_repository.dart';

void main() {
  group('parseYoutubeVideoId', () {
    const id = 'dQw4w9WgXcQ';

    test('reads the common link shapes', () {
      for (final url in [
        'https://youtu.be/$id',
        'https://youtu.be/$id?si=abc',
        'https://www.youtube.com/watch?v=$id',
        'https://www.youtube.com/watch?v=$id&list=PL123&t=30s',
        'https://m.youtube.com/watch?v=$id',
        'https://music.youtube.com/watch?v=$id',
        'https://www.youtube.com/shorts/$id',
        'https://www.youtube.com/embed/$id',
        'https://www.youtube.com/live/$id',
      ]) {
        expect(parseYoutubeVideoId(url), id, reason: url);
      }
    });

    test('finds the link inside shared text', () {
      expect(parseYoutubeVideoId('Great talk https://youtu.be/$id'), id);
    });

    test('returns null when there is no video link', () {
      for (final text in [
        '',
        'just words',
        'https://www.youtube.com/playlist?list=PL123',
        'https://www.youtube.com/@somechannel',
        'https://example.com/watch?v=$id',
        'https://notyoutube.com/watch?v=$id',
        'https://youtu.be/short',
      ]) {
        expect(parseYoutubeVideoId(text), isNull, reason: text);
      }
    });
  });

  group('SaveSharedVideoUsecase', () {
    late FakeVideoRepository videos;
    late FakeVideoMetadataRepository metadata;
    final now = DateTime(2026, 5, 1);

    SaveSharedVideoUsecase usecase() =>
        SaveSharedVideoUsecase(videos, metadata, now: () => now);

    SaveSharedVideoArgumentModel arg(String text, {String? folder = 'f'}) =>
        SaveSharedVideoArgumentModel(
          videoId: 'v1',
          sharedText: text,
          folderId: folder,
        );

    setUp(() {
      videos = FakeVideoRepository();
      metadata = FakeVideoMetadataRepository();
    });

    test('saves the video with the oEmbed details', () async {
      metadata.response = const VideoMetadataModel(
        title: 'How tides work',
        channelName: 'Veritasium',
        thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );

      final result = await usecase()(arg('https://youtu.be/dQw4w9WgXcQ'));

      expect(result, isA<Ok<void>>());
      expect(metadata.requested, ['dQw4w9WgXcQ']);
      final saved = videos.byId('v1')!;
      expect(saved.folderId, 'f');
      expect(saved.youtubeVideoId, 'dQw4w9WgXcQ');
      expect(saved.title, 'How tides work');
      expect(saved.channelName, 'Veritasium');
      expect(saved.createdAt, now);
    });

    test('still saves, with fallback details, when the lookup fails', () async {
      metadata.response = null;

      final result = await usecase()(arg('https://youtu.be/dQw4w9WgXcQ'));

      expect(result, isA<Ok<void>>());
      final saved = videos.byId('v1')!;
      expect(saved.title, fallbackVideoTitle);
      expect(saved.thumbnailUrl,
          'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg');
    });

    test('rejects text that holds no video link, without a lookup', () async {
      final result = await usecase()(arg('https://example.com'));

      expect((result as Err).failure, isA<ValidationFailure>());
      expect(metadata.requested, isEmpty);
      expect(videos.videos, isEmpty);
    });

    test('passes a storage failure through', () async {
      videos.failWith = const StorageFailure('boom');

      final result = await usecase()(arg('https://youtu.be/dQw4w9WgXcQ'));

      expect((result as Err).failure, isA<StorageFailure>());
    });
  });

  group('RenameVideoUsecase', () {
    test('trims the title', () async {
      final videos = FakeVideoRepository()..add('v', null);

      final result = await RenameVideoUsecase(videos)('v', '  New  ');

      expect(result, isA<Ok<void>>());
      expect(videos.byId('v')!.title, 'New');
    });

    test('rejects an empty title', () async {
      final videos = FakeVideoRepository()..add('v', null, title: 'Old');

      final result = await RenameVideoUsecase(videos)('v', ' ');

      expect((result as Err).failure, isA<ValidationFailure>());
      expect(videos.byId('v')!.title, 'Old');
    });
  });

  group('ReorderVideosUsecase', () {
    late FakeVideoRepository videos;

    setUp(() {
      videos = FakeVideoRepository()
        ..add('a', 'f')
        ..add('b', 'f')
        ..add('c', 'f');
    });

    test('accepts a full permutation', () async {
      final result = await ReorderVideosUsecase(videos)('f', ['b', 'c', 'a']);

      expect(result, isA<Ok<void>>());
      expect(videos.reorderedTo, ['b', 'c', 'a']);
    });

    test('rejects a missing, duplicate or foreign id', () async {
      videos.add('x', 'other');
      final usecase = ReorderVideosUsecase(videos);

      for (final ids in [
        ['a', 'b'],
        ['a', 'a', 'b'],
        ['a', 'b', 'x'],
      ]) {
        final result = await usecase('f', ids);
        expect((result as Err).failure, isA<ValidationFailure>(),
            reason: '$ids');
      }
      expect(videos.reorderedTo, isNull);
    });
  });
}
