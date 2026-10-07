import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_play_queue/get_play_queue_return_model.dart';

/// The videos the player steps through: the folder's direct videos only.
class GetPlayQueueUsecase {
  final VideoRepositoryInterface _videos;

  GetPlayQueueUsecase(this._videos);

  Future<Result<GetPlayQueueReturnModel>> call(String? folderId) async {
    final videos = await _videos.getVideos(folderId);
    return videos.map((v) => GetPlayQueueReturnModel(videos: v));
  }
}
