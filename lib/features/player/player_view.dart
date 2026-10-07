import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/core/widgets/obx_value.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_play_queue/get_play_queue_return_model.dart';
import 'package:youtube_saver/features/player/player_view_model.dart';
import 'package:youtube_saver/features/shared/failure_message.dart';
import 'package:youtube_saver/features/shared/widgets/app_row.dart';
import 'package:youtube_saver/features/shared/widgets/app_switch.dart';
import 'package:youtube_saver/features/shared/widgets/pill_button.dart';
import 'package:youtube_saver/features/shared/widgets/video_tile.dart';

class PlayerView extends StatefulWidget {
  final PlayerBundle bundle;
  const PlayerView({super.key, required this.bundle});

  static Future<void> open(BuildContext context, PlayerBundle bundle) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerView(bundle: bundle)),
    );
  }

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  late final PlayerViewModel ctrl;
  late final YoutubePlayerController _player;
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;
  final ValueNotifier<bool> _playing = ValueNotifier(false);
  final ValueNotifier<bool> _fullscreen = ValueNotifier(false);

  String? _loadedRowId; // the saved video that is loaded in the player
  PlayerState? _lastState;
  bool _errorHandled = false;
  String? _lastErrorName; // shown in debug builds to help diagnose setup errors

  /// Errors that mean this particular video cannot be played in an embed.
  static const _embedRestricted = {
    YoutubeError.notEmbeddable,
    YoutubeError.sameAsNotEmbeddable,
    YoutubeError.videoNotFound,
    YoutubeError.cannotFindVideo,
  };

  @override
  void initState() {
    super.initState();
    ctrl = PlayerViewModel(
      bundle: widget.bundle,
      getPlayQueue: AppDependencies.instance.getPlayQueue,
      getFolderPath: AppDependencies.instance.getFolderPath,
    );
    _player = YoutubePlayerController(
      params: const YoutubePlayerParams(
        // YouTube's own full screen button is hidden: inside a WebView it only
        // fills the page and never rotates. The app draws its own button.
        showFullscreenButton: false,
        // YouTube refuses embeds (error 153) that carry no usable origin.
        origin: 'https://www.youtube-nocookie.com',
      ),
    );
    _playerSubscription = _player.stream.listen(_onPlayerValue);
    ctrl.queue.addListener(_loadCurrent);
    ctrl.index.addListener(_loadCurrent);
  }

  /// Loads the current video into the player when it changes.
  void _loadCurrent() {
    final video = ctrl.current;
    if (video == null || video.id == _loadedRowId) return;

    _loadedRowId = video.id;
    _lastState = null;
    _errorHandled = false;
    // Clear what the previous video left behind, so it is not read as this one's.
    _player.update(
      error: YoutubeError.none,
      playerState: PlayerState.unStarted,
    );
    _player.loadVideoById(videoId: video.youtubeVideoId);
  }

  void _onPlayerValue(YoutubePlayerValue value) {
    _playing.value = value.playerState == PlayerState.playing;
    _fullscreen.value = value.fullScreenOption.enabled;

    final id = _loadedRowId;
    if (id == null) return;

    if (value.hasError) {
      if (!_errorHandled) {
        _errorHandled = true;
        debugPrint('YouTube player error: ${value.error.name}');
        _lastErrorName = value.error.name;
        if (_embedRestricted.contains(value.error)) {
          ctrl.onUnplayable(id);
        } else {
          // 152/153 (no embed origin), html5 and param errors are not about the
          // video, so the video is not marked and the queue is not skipped.
          ctrl.onPlayerError(id);
        }
      }
      return;
    }
    if (value.playerState == PlayerState.ended &&
        _lastState != PlayerState.ended) {
      ctrl.onEnded(id);
    }
    _lastState = value.playerState;
  }

  void _retry() {
    ctrl.clearPlayerError();
    _loadedRowId = null;
    _loadCurrent();
  }

  void _replay() {
    ctrl.replay();
    _loadedRowId = null; // the first video may be the one already loaded
    _loadCurrent();
  }

  void _togglePlay() {
    if (_playing.value) {
      _player.pauseVideo();
    } else {
      _player.playVideo();
    }
  }

  @override
  void dispose() {
    ctrl.queue.removeListener(_loadCurrent);
    ctrl.index.removeListener(_loadCurrent);
    _playerSubscription?.cancel();
    _player.close();
    _playing.dispose();
    _fullscreen.dispose();
    // Leaving while full screen must not leave the app in landscape.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _openInYoutube(VideoModel video) {
    return launchUrl(
      Uri.parse('https://www.youtube.com/watch?v=${video.youtubeVideoId}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Back leaves full screen first, then the screen.
    return ObxValue<bool>(
      listenable: _fullscreen,
      builder: (fullscreen) => PopScope(
        canPop: !fullscreen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _player.exitFullScreen();
        },
        child: Stack(
          children: [
            _scaffold(),
            if (fullscreen)
              Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: _roundButton(
                    Icons.fullscreen_exit_rounded,
                    'Exit full screen',
                    _player.exitFullScreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A round translucent button that sits on the video.
  Widget _roundButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0x66000000),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _scaffold() {
    return YoutubePlayerScaffold(
      controller: _player,
      aspectRatio: 16 / 9,
      // Portrait unless full screen. Rotating the phone does not enter it.
      defaultOrientations: const [DeviceOrientation.portraitUp],
      autoFullScreen: false,
      builder: (context, player) => SafeArea(
        bottom: false,
        child: Scaffold(
          body: ObxMulti(
            listenables: [
              ctrl.queue,
              ctrl.index,
              ctrl.autoAdvance,
              ctrl.unplayable,
              ctrl.finished,
              ctrl.playerError,
              ctrl.skipping,
              ctrl.folderName,
            ],
            builder: () => ctrl.queue.value.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (failure) => Center(child: Text(messageFor(failure))),
              loaded: (queue) => queue.videos.isEmpty
                  ? const Center(child: Text('No videos in this folder.'))
                  : _body(player, queue),
            ),
          ),
        ),
      ),
    );
  }

  /// The black area over the player for "can't embed" and "queue finished".
  Widget _overlay(
    String message,
    String button,
    VoidCallback onPressed, {
    String? secondButton,
    VoidCallback? onSecondPressed,
  }) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFFDDDDDD),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  PillButton(label: button, onDark: true, onPressed: onPressed),
                  if (secondButton != null)
                    PillButton(
                      label: secondButton,
                      onDark: true,
                      onPressed: onSecondPressed,
                    ),
                ],
              ),
              if (kDebugMode && _lastErrorName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'debug: $_lastErrorName',
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _control(
    IconData icon, {
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    final c = context.colors;
    return Opacity(
      opacity: onPressed == null ? 0.3 : 1,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 24,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: c.text),
      ),
    );
  }

  Widget _body(Widget player, GetPlayQueueReturnModel queue) {
    final c = context.colors;
    final index = ctrl.index.value;
    final current = queue.videos[index];
    final blocked = ctrl.unplayable.value.contains(current.id);
    final finished = ctrl.finished.value;
    final folder = ctrl.folderName.value;
    final upNext = [for (var i = index; i < queue.videos.length; i++) i];

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              player,
              if (finished)
                _overlay('Queue finished', 'Replay folder', _replay)
              else if (blocked)
                _overlay(
                  "This video can't be played in the app.",
                  'Open in YouTube',
                  () => _openInYoutube(current),
                )
              else if (ctrl.playerError.value)
                _overlay(
                  "The player couldn't start this video.",
                  'Try again',
                  _retry,
                  secondButton: 'Open in YouTube',
                  onSecondPressed: () => _openInYoutube(current),
                ),
              if (!finished && !blocked && !ctrl.playerError.value)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: _roundButton(
                    Icons.fullscreen_rounded,
                    'Full screen',
                    _player.enterFullScreen,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder,
                  style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    current.title,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.36,
                      color: c.text,
                    ),
                  ),
                ),
                if (finished || current.channelName.isNotEmpty)
                  Text(
                    finished
                        ? 'Last video in this folder'
                        : current.channelName,
                    style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _control(
                Icons.skip_previous_rounded,
                tooltip: 'Previous',
                onPressed: index > 0 ? ctrl.previous : null,
              ),
              const SizedBox(width: 28),
              ObxValue<bool>(
                listenable: _playing,
                builder: (playing) => Material(
                  color: c.text,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _togglePlay,
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: c.bg,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 28),
              _control(
                Icons.skip_next_rounded,
                tooltip: 'Next',
                onPressed: index < queue.videos.length - 1 ? ctrl.next : null,
              ),
            ],
          ),
        ),
        if (ctrl.skipping.value)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'Skipping to the next video in ${ctrl.skipDelay.inSeconds}s…',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: c.line)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auto-advance',
                style: TextStyle(fontSize: 14, height: 1.4, color: c.text),
              ),
              AppSwitch(
                value: ctrl.autoAdvance.value,
                onChanged: (_) => ctrl.toggleAutoAdvance(),
              ),
            ],
          ),
        ),
        SectionLabel('Up next · $folder'),
        Expanded(
          child: ListView(
            children: dividedRows(context, [
              for (final i in upNext)
                VideoTile(
                  video: queue.videos[i],
                  current: i == index,
                  subtitle: i == index
                      ? (blocked ? 'Unavailable' : 'Playing')
                      : null,
                  onTap: () => ctrl.select(i),
                  trailing:
                      i != index &&
                          ctrl.unplayable.value.contains(queue.videos[i].id)
                      ? RowGlyph('×')
                      : null,
                ),
            ]),
          ),
        ),
      ],
    );
  }
}
