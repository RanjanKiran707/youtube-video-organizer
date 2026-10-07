import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';

/// A use case, although it only passes through, because the folder view and
/// the player both offer "move".
class MoveVideoUsecase {
  final VideoRepositoryInterface _videos;

  MoveVideoUsecase(this._videos);

  Future<Result<void>> call(String videoId, String? newFolderId) {
    return _videos.moveVideo(videoId, newFolderId);
  }
}
