import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_repository_interface.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/save_shared_video_argument_model.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/youtube_url_parser.dart';

const fallbackVideoTitle = 'YouTube video';

class SaveSharedVideoUsecase {
  final VideoRepositoryInterface _videos;
  final VideoMetadataRepositoryInterface _metadata;
  final DateTime Function() _now;

  SaveSharedVideoUsecase(this._videos, this._metadata,
      {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  /// Saves the shared video into the folder. If the oEmbed lookup fails (offline,
  /// private video), the video is still saved with a generic title and the
  /// standard thumbnail URL, so a share is never lost; the user can rename it.
  Future<Result<void>> call(SaveSharedVideoArgumentModel model) async {
    final youtubeId = parseYoutubeVideoId(model.sharedText);
    if (youtubeId == null) {
      return const Err(ValidationFailure('not_a_youtube_video'));
    }

    final lookup = await _metadata.fetch(youtubeId);
    final (title, channel, thumbnail) = switch (lookup) {
      Ok(:final value) => (value.title, value.channelName, value.thumbnailUrl),
      Err() => (
          fallbackVideoTitle,
          '',
          'https://i.ytimg.com/vi/$youtubeId/hqdefault.jpg',
        ),
    };

    return _videos.addVideo(
      VideoModel(
        id: model.videoId,
        folderId: model.folderId,
        youtubeVideoId: youtubeId,
        title: title,
        channelName: channel,
        thumbnailUrl: thumbnail,
        durationSeconds: null,
        position: 0, // the repository appends it at the end
        createdAt: _now(),
      ),
    );
  }
}
