import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video/video_model.dart';

abstract interface class VideoRepositoryInterface {
  /// Adds the video at the end of its folder. `video.position` is ignored.
  Future<Result<void>> addVideo(VideoModel video);

  Future<Result<void>> renameVideo(String videoId, String title);

  Future<Result<void>> deleteVideo(String videoId);

  /// Moves the video to the end of [newFolderId] (null = root).
  Future<Result<void>> moveVideo(String videoId, String? newFolderId);

  /// Sets the play order of [folderId] to [orderedVideoIds].
  Future<Result<void>> reorderVideos(
    String? folderId,
    List<String> orderedVideoIds,
  );

  /// One-time read of the videos directly inside [folderId], in play order.
  Future<Result<List<VideoModel>>> getVideos(String? folderId);

  /// Emits the full list again whenever the videos of [folderId] change.
  Stream<Result<List<VideoModel>>> watchVideos(String? folderId);
}
