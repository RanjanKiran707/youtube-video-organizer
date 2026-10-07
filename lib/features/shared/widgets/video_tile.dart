import 'package:flutter/material.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/features/shared/widgets/video_thumbnail.dart';

class VideoTile extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Highlights the row, for the video that is playing.
  final bool current;

  const VideoTile({
    super.key,
    required this.video,
    required this.onTap,
    this.trailing,
    this.current = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      tileColor: current ? scheme.surfaceContainerHighest : null,
      leading: VideoThumbnail(url: video.thumbnailUrl),
      title: Text(
        video.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: current ? TextStyle(color: scheme.primary) : null,
      ),
      subtitle: video.channelName.isEmpty ? null : Text(video.channelName),
      trailing: trailing,
    );
  }
}
