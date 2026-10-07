import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';

abstract interface class FolderRepositoryInterface {
  /// Adds the folder at the end of its parent. `folder.position` is ignored.
  Future<Result<void>> createFolder(FolderModel folder);

  Future<Result<void>> renameFolder(String folderId, String name);

  /// Deletes the folder with its subfolders and videos.
  Future<Result<void>> deleteFolder(String folderId);

  /// Moves the folder to the end of [newParentId] (null = root).
  /// The caller makes sure the target is not the folder itself or a descendant.
  Future<Result<void>> moveFolder(String folderId, String? newParentId);

  /// Sets the order of the children of [parentId] to [orderedFolderIds].
  Future<Result<void>> reorderFolders(
    String? parentId,
    List<String> orderedFolderIds,
  );

  /// One-time read of the folders directly inside [parentId], in order.
  Future<Result<List<FolderModel>>> getChildren(String? parentId);

  /// Folders from the root down to [folderId], including it. Used for breadcrumbs.
  Future<Result<List<FolderModel>>> getPath(String folderId);

  /// Emits the full list again whenever the children of [parentId] change.
  Stream<Result<List<FolderModel>>> watchChildren(String? parentId);
}
