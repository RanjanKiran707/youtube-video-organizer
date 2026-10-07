import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/core/widgets/obx_value.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_play_queue/get_play_queue_return_model.dart';
import 'package:youtube_saver/features/player/player_view_model.dart';
import 'package:youtube_saver/features/shared/failure_message.dart';
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

  String? _loadedRowId; // the saved video that is loaded in the player
  PlayerState? _lastState;
  bool _errorHandled = false;

  @override
  void initState() {
    super.initState();
    ctrl = PlayerViewModel(
      bundle: widget.bundle,
      getPlayQueue: AppDependencies.instance.getPlayQueue,
    );
    _player = YoutubePlayerController(
      params: const YoutubePlayerParams(showFullscreenButton: true),
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
    final id = _loadedRowId;
    if (id == null) return;

    if (value.hasError) {
      if (!_errorHandled) {
        _errorHandled = true;
        ctrl.onUnplayable(id);
      }
      return;
    }
    if (value.playerState == PlayerState.ended &&
        _lastState != PlayerState.ended) {
      ctrl.onEnded(id);
    }
    _lastState = value.playerState;
  }

  @override
  void dispose() {
    ctrl.queue.removeListener(_loadCurrent);
    ctrl.index.removeListener(_loadCurrent);
    _playerSubscription?.cancel();
    _player.close();
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
    return YoutubePlayerScaffold(
      controller: _player,
      aspectRatio: 16 / 9,
      builder: (context, player) => Scaffold(
        appBar: AppBar(title: const Text('Now playing')),
        body: ObxMulti(
          listenables: [
            ctrl.queue,
            ctrl.index,
            ctrl.autoAdvance,
            ctrl.unplayable,
            ctrl.finished,
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
    );
  }

  Widget _body(Widget player, GetPlayQueueReturnModel queue) {
    final scheme = Theme.of(context).colorScheme;
    final index = ctrl.index.value;
    final current = queue.videos[index];
    final blocked = ctrl.unplayable.value.contains(current.id);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              player,
              if (blocked)
                ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "This video can't be played in the app.",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _openInYoutube(current),
                          child: const Text('Open in YouTube'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (current.channelName.isNotEmpty)
                  Text(
                    current.channelName,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous',
                onPressed: index > 0 ? ctrl.previous : null,
                icon: const Icon(Icons.skip_previous),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: index < queue.videos.length - 1 ? ctrl.next : null,
                icon: const Icon(Icons.skip_next),
              ),
              const Spacer(),
              const Text('Auto-advance'),
              Switch(
                value: ctrl.autoAdvance.value,
                onChanged: (_) => ctrl.toggleAutoAdvance(),
              ),
            ],
          ),
        ),
        if (ctrl.finished.value)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Queue finished. That was the last video in this folder.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'UP NEXT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: queue.videos.length,
            itemBuilder: (context, i) {
              final video = queue.videos[i];
              return VideoTile(
                video: video,
                current: i == index,
                onTap: () => ctrl.select(i),
                trailing: ctrl.unplayable.value.contains(video.id)
                    ? const Icon(Icons.block, size: 18)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
