import 'package:youtube_saver/data/video/video_model.dart';

class GetPlayQueueReturnModel {
  /// The folder's direct videos in play order. Subfolders are not included.
  final List<VideoModel> videos;

  const GetPlayQueueReturnModel({required this.videos});

  /// Index of the video to start from, or 0 when [videoId] is not in the queue.
  int indexOf(String? videoId) {
    final index = videos.indexWhere((v) => v.id == videoId);
    return index < 0 ? 0 : index;
  }
}
