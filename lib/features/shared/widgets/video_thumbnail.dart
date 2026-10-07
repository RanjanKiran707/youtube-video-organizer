import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';

/// The mockup's `.thumb`: a rounded image, with the duration in the corner
/// when it is known.
class VideoThumbnail extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final int? durationSeconds;

  const VideoThumbnail({
    super.key,
    required this.url,
    this.width = 72,
    this.height = 40,
    this.durationSeconds,
  });

  static String formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(color: context.colors.thumb);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
            if (durationSeconds != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xAA000000),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    formatDuration(durationSeconds!),
                    style: const TextStyle(
                      fontSize: 9,
                      height: 1.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
