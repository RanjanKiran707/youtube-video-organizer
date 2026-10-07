import 'package:flutter/material.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/features/shared/widgets/app_row.dart';
import 'package:youtube_saver/features/shared/widgets/video_thumbnail.dart';

class VideoTile extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Highlights the row, for the video that is playing.
  final bool current;

  /// Replaces the channel name ("Playing", "Unavailable").
  final String? subtitle;

  const VideoTile({
    super.key,
    required this.video,
    required this.onTap,
    this.trailing,
    this.current = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final line = subtitle ?? video.channelName;

    return AppRow(
      onTap: onTap,
      highlighted: current,
      leading: VideoThumbnail(
        url: video.thumbnailUrl,
        durationSeconds: video.durationSeconds,
      ),
      title: video.title,
      subtitle: line.isEmpty ? null : line,
      trailing: trailing,
    );
  }
}
