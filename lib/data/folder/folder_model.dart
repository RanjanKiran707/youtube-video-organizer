class FolderModel {
  final String id;
  final String? parentId; // foreign key -> FolderModel.id, null = library root
  final String name;
  final int position; // order among siblings
  final DateTime createdAt;

  const FolderModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.position,
    required this.createdAt,
  });
}
