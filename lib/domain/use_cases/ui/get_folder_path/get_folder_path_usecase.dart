import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';

/// Breadcrumb for a folder, root first, the folder itself last.
/// The library root (null) has an empty path.
class GetFolderPathUsecase {
  final FolderRepositoryInterface _folders;

  GetFolderPathUsecase(this._folders);

  Future<Result<List<FolderModel>>> call(String? folderId) {
    if (folderId == null) return Future.value(const Ok(<FolderModel>[]));
    return _folders.getPath(folderId);
  }
}
