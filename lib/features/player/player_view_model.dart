import 'package:flutter/foundation.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_play_queue/get_play_queue_return_model.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_play_queue/get_play_queue_usecase.dart';

class PlayerBundle {
  final String? folderId; // null = library root
  final String? startVideoId; // null = start at the first video

  const PlayerBundle({this.folderId, this.startVideoId});
}

/// Steps through the direct videos of one folder. The View reports what the
/// YouTube player does (`onEnded`, `onUnplayable`); this decides what plays next.
class PlayerViewModel {
  final PlayerBundle bundle;
  final GetPlayQueueUsecase _getPlayQueue;

  final ValueNotifier<ViewState<GetPlayQueueReturnModel>> queue = ValueNotifier(
    const ViewStateLoading(),
  );

  /// Position of the current video in the queue.
  final ValueNotifier<int> index = ValueNotifier(0);

  final ValueNotifier<bool> autoAdvance = ValueNotifier(true);

  /// Ids of videos that could not be played in the app (not embeddable).
  final ValueNotifier<Set<String>> unplayable = ValueNotifier(const {});

  /// True after the last video ended or failed with nothing left to play.
  final ValueNotifier<bool> finished = ValueNotifier(false);

  bool _disposed = false;

  PlayerViewModel({
    required this.bundle,
    required GetPlayQueueUsecase getPlayQueue,
  }) : _getPlayQueue = getPlayQueue {
    _load();
  }

  List<VideoModel> get _videos => switch (queue.value) {
    ViewStateLoaded(:final data) => data.videos,
    _ => const [],
  };

  VideoModel? get current {
    final videos = _videos;
    return index.value < videos.length ? videos[index.value] : null;
  }

  Future<void> _load() async {
    final result = await _getPlayQueue(bundle.folderId);
    if (_disposed) return;

    switch (result) {
      case Err(:final failure):
        queue.value = ViewStateError(failure);
      case Ok(:final value):
        // Index first, so listeners of `queue` already see the start video.
        index.value = value.indexOf(bundle.startVideoId);
        queue.value = ViewStateLoaded(value);
    }
  }

  void select(int i) {
    if (i < 0 || i >= _videos.length) return;
    finished.value = false;
    index.value = i;
  }

  void next() => select(index.value + 1);

  void previous() => select(index.value - 1);

  void toggleAutoAdvance() => autoAdvance.value = !autoAdvance.value;

  /// The player finished [videoId]. Ignored for any other video, so a late
  /// event cannot skip a video that is already playing.
  void onEnded(String videoId) {
    if (current?.id != videoId || finished.value) return;
    if (autoAdvance.value) _advance();
  }

  /// The player could not play [videoId] (private, deleted, embedding off).
  /// It is marked, and skipped when auto-advance is on.
  void onUnplayable(String videoId) {
    if (current?.id != videoId) return;
    unplayable.value = {...unplayable.value, videoId};
    if (autoAdvance.value) _advance();
  }

  void _advance() {
    final videos = _videos;
    for (var i = index.value + 1; i < videos.length; i++) {
      if (!unplayable.value.contains(videos[i].id)) {
        index.value = i;
        return;
      }
    }
    finished.value = true; // end of the folder: playback stops
  }

  void dispose() {
    _disposed = true;
    queue.dispose();
    index.dispose();
    autoAdvance.dispose();
    unplayable.dispose();
    finished.dispose();
  }
}
