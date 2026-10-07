class SaveSharedVideoArgumentModel {
  final String videoId; // new id for the saved row
  final String sharedText; // what the share sheet sent, usually a URL
  final String? folderId; // null = library root

  const SaveSharedVideoArgumentModel({
    required this.videoId,
    required this.sharedText,
    required this.folderId,
  });
}
