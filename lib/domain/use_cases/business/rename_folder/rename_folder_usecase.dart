import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';
import 'package:youtube_saver/domain/use_cases/business/shared/folder_name_rules.dart';

class RenameFolderUsecase {
  final FolderRepositoryInterface _folders;

  RenameFolderUsecase(this._folders);

  Future<Result<void>> call(String folderId, String name) async {
    final path = await _folders.getPath(folderId);
    switch (path) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final folder = value.last;
        final siblings = await _folders.getChildren(folder.parentId);
        final valid = siblings.flatMap(
          (s) => validateFolderName(name, s, exceptId: folderId),
        );
        switch (valid) {
          case Err(:final failure):
            return Err(failure);
          case Ok(:final value):
            return _folders.renameFolder(folderId, value);
        }
    }
  }
}
