import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';

class DeleteVideoUsecase {
  final VideoRepositoryInterface _videos;

  DeleteVideoUsecase(this._videos);

  Future<Result<void>> call(String videoId) => _videos.deleteVideo(videoId);
}
