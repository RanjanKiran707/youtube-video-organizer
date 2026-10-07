import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_model.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_repository.dart';

void main() {
  test('fetch maps the oEmbed response and asks for the right video', () async {
    late Uri requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(
        '{"title":"How tides work","author_name":"Veritasium",'
        '"thumbnail_url":"https://i.ytimg.com/vi/abc/hqdefault.jpg"}',
        200,
      );
    });

    final result = await VideoMetadataRepository(client).fetch('abc');

    final metadata = (result as Ok<VideoMetadataModel>).value;
    expect(metadata.title, 'How tides work');
    expect(metadata.channelName, 'Veritasium');
    expect(metadata.thumbnailUrl, 'https://i.ytimg.com/vi/abc/hqdefault.jpg');
    expect(requested.path, '/oembed');
    expect(requested.queryParameters['url'],
        'https://www.youtube.com/watch?v=abc');
  });

  test('a non-200 status (private or deleted video) is a NetworkFailure',
      () async {
    final client = MockClient((_) async => http.Response('Not Found', 404));

    final result = await VideoMetadataRepository(client).fetch('abc');

    expect((result as Err<VideoMetadataModel>).failure, isA<NetworkFailure>());
  });

  test('being offline is a NetworkFailure', () async {
    final client = MockClient((_) async => throw const SocketException('x'));

    final result = await VideoMetadataRepository(client).fetch('abc');

    expect((result as Err<VideoMetadataModel>).failure, isA<NetworkFailure>());
  });

  test('a malformed response is a NetworkFailure, not a crash', () async {
    final client = MockClient((_) async => http.Response('{"title":1}', 200));

    final result = await VideoMetadataRepository(client).fetch('abc');

    expect(result, isA<Err<VideoMetadataModel>>());
  });
}
