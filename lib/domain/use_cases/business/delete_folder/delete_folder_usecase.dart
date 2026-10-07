import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';

/// Deletes the folder with its subfolders and videos (cascade in the database).
class DeleteFolderUsecase {
  final FolderRepositoryInterface _folders;

  DeleteFolderUsecase(this._folders);

  Future<Result<void>> call(String folderId) => _folders.deleteFolder(folderId);
}
