import 'package:youtube_saver/data/video/video_model.dart';

/// A subfolder plus what it holds directly, for the "2 videos · 1 folder" line.
class FolderItem {
  final String id;
  final String name;
  final int videoCount;
  final int folderCount;

  const FolderItem({
    required this.id,
    required this.name,
    required this.videoCount,
    required this.folderCount,
  });
}

class ListFolderContentsReturnModel {
  final List<FolderItem> folders;
  final List<VideoModel> videos;

  const ListFolderContentsReturnModel({
    required this.folders,
    required this.videos,
  });

  bool get isEmpty => folders.isEmpty && videos.isEmpty;
}
