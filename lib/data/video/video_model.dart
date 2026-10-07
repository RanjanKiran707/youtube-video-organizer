class VideoModel {
  final String id;
  final String? folderId; // foreign key -> FolderModel.id, null = library root
  final String youtubeVideoId;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final int? durationSeconds; // null when unknown
  final int position; // play order within the folder
  final DateTime createdAt;

  const VideoModel({
    required this.id,
    required this.folderId,
    required this.youtubeVideoId,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.position,
    required this.createdAt,
  });
}
