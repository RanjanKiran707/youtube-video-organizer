import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';

class ReorderVideosUsecase {
  final VideoRepositoryInterface _videos;

  ReorderVideosUsecase(this._videos);

  /// [orderedVideoIds] must list every video in [folderId] exactly once.
  Future<Result<void>> call(
    String? folderId,
    List<String> orderedVideoIds,
  ) async {
    final videos = await _videos.getVideos(folderId);
    switch (videos) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final current = value.map((v) => v.id).toSet();
        final given = orderedVideoIds.toSet();
        if (given.length != orderedVideoIds.length ||
            given.length != current.length ||
            !given.containsAll(current)) {
          return const Err(ValidationFailure('reorder_mismatch'));
        }
        return _videos.reorderVideos(folderId, orderedVideoIds);
    }
  }
}
