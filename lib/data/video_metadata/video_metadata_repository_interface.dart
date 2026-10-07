import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_model.dart';

abstract interface class VideoMetadataRepositoryInterface {
  /// Looks up title, channel and thumbnail. Returns `Err(NetworkFailure)` when
  /// the device is offline or the video is private or deleted.
  Future<Result<VideoMetadataModel>> fetch(String youtubeVideoId);
}
