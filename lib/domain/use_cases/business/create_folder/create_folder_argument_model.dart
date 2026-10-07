class CreateFolderArgumentModel {
  final String folderId;
  final String? parentId; // null = library root
  final String name;

  const CreateFolderArgumentModel({
    required this.folderId,
    required this.parentId,
    required this.name,
  });
}
