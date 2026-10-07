/// What YouTube's oEmbed endpoint tells us about a video.
class VideoMetadataModel {
  final String title;
  final String channelName;
  final String thumbnailUrl;

  const VideoMetadataModel({
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
  });
}
