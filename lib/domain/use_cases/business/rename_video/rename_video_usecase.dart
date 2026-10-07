import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';

class RenameVideoUsecase {
  final VideoRepositoryInterface _videos;

  RenameVideoUsecase(this._videos);

  Future<Result<void>> call(String videoId, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Err(ValidationFailure('title_required')));
    }
    return _videos.renameVideo(videoId, trimmed);
  }
}
