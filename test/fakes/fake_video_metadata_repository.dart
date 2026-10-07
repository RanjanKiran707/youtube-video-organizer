import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_model.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_repository_interface.dart';

class FakeVideoMetadataRepository implements VideoMetadataRepositoryInterface {
  /// Null makes `fetch` fail like an offline lookup.
  VideoMetadataModel? response;
  final List<String> requested = [];

  @override
  Future<Result<VideoMetadataModel>> fetch(String youtubeVideoId) async {
    requested.add(youtubeVideoId);
    final r = response;
    return r == null ? const Err(NetworkFailure('offline')) : Ok(r);
  }
}
