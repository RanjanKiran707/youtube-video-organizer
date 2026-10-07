import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_model.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_repository_interface.dart';

/// Uses YouTube's oEmbed endpoint. No API key is needed.
class VideoMetadataRepository implements VideoMetadataRepositoryInterface {
  final http.Client _client;

  VideoMetadataRepository(this._client);

  @override
  Future<Result<VideoMetadataModel>> fetch(String youtubeVideoId) async {
    try {
      final uri = Uri.https('www.youtube.com', '/oembed', {
        'url': 'https://www.youtube.com/watch?v=$youtubeVideoId',
        'format': 'json',
      });
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode != 200) {
        return Err(NetworkFailure('oembed_status_${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(VideoMetadataModel(
        title: json['title'] as String,
        channelName: json['author_name'] as String,
        thumbnailUrl: json['thumbnail_url'] as String,
      ));
    } catch (e) {
      return Err(NetworkFailure(e.toString()));
    }
  }
}
