import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
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
  final GetFolderPathUsecase _getFolderPath;

  /// How long "Skipping to the next video…" shows before it moves on.
  final Duration skipDelay;

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

  /// Name of the folder being played, for the crumb and the "Up next" label.
  final ValueNotifier<String> folderName = ValueNotifier('Library');

  /// True while an unplayable video waits to be skipped.
  final ValueNotifier<bool> skipping = ValueNotifier(false);

  /// True when the player failed on the current video for a reason that says
  /// nothing about the video itself (a player or setup error). Such a video is
  /// not marked and not skipped, so one setup problem cannot clear the queue.
  final ValueNotifier<bool> playerError = ValueNotifier(false);

  Timer? _skipTimer;
  bool _disposed = false;

  PlayerViewModel({
    required this.bundle,
    required GetPlayQueueUsecase getPlayQueue,
    required GetFolderPathUsecase getFolderPath,
    this.skipDelay = const Duration(seconds: 3),
  }) : _getPlayQueue = getPlayQueue,
       _getFolderPath = getFolderPath {
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
    final path = await _getFolderPath(bundle.folderId);
    if (_disposed) return;
    if (path case Ok(value: final folders) when folders.isNotEmpty) {
      folderName.value = folders.last.name;
    }

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
    _cancelSkip();
    playerError.value = false;
    finished.value = false;
    index.value = i;
  }

  void next() => select(index.value + 1);

  void previous() => select(index.value - 1);

  void toggleAutoAdvance() {
    autoAdvance.value = !autoAdvance.value;
    if (!autoAdvance.value) _cancelSkip();
  }

  /// Starts the folder again from its first video.
  void replay() {
    _cancelSkip();
    playerError.value = false;
    finished.value = false;
    index.value = 0;
  }

  /// The player failed on [videoId] for a reason that is not about the video
  /// (for example a missing embed origin). Nothing is marked or skipped.
  void onPlayerError(String videoId) {
    if (current?.id != videoId) return;
    playerError.value = true;
  }

  void clearPlayerError() => playerError.value = false;

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
    if (!autoAdvance.value) return;

    if (_nextPlayable() == null) {
      finished.value = true;
      return;
    }
    skipping.value = true;
    _skipTimer = Timer(skipDelay, () {
      skipping.value = false;
      _advance();
    });
  }

  int? _nextPlayable() {
    final videos = _videos;
    for (var i = index.value + 1; i < videos.length; i++) {
      if (!unplayable.value.contains(videos[i].id)) return i;
    }
    return null;
  }

  void _advance() {
    final next = _nextPlayable();
    if (next == null) {
      finished.value = true; // end of the folder: playback stops
    } else {
      playerError.value = false;
      index.value = next;
    }
  }

  void _cancelSkip() {
    _skipTimer?.cancel();
    _skipTimer = null;
    skipping.value = false;
  }

  void dispose() {
    _disposed = true;
    _skipTimer?.cancel();
    queue.dispose();
    index.dispose();
    autoAdvance.dispose();
    unplayable.dispose();
    finished.dispose();
    folderName.dispose();
    skipping.dispose();
    playerError.dispose();
  }
}
