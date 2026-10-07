import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';
import 'package:youtube_saver/domain/use_cases/business/shared/folder_name_rules.dart';

class MoveFolderUsecase {
  final FolderRepositoryInterface _folders;

  MoveFolderUsecase(this._folders);

  /// Moves [folderId] under [newParentId] (null = library root). A folder
  /// cannot go into itself or into one of its own subfolders.
  Future<Result<void>> call(String folderId, String? newParentId) async {
    final own = await _folders.getPath(folderId);
    switch (own) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final folder = value.last;

        if (newParentId != null) {
          final target = await _folders.getPath(newParentId);
          switch (target) {
            case Err(:final failure):
              return Err(failure);
            case Ok(:final value):
              // The target's path runs root -> target, so the moved folder is
              // in it when the target is that folder or one of its descendants.
              if (value.any((f) => f.id == folderId)) {
                return const Err(ValidationFailure('move_into_itself'));
              }
          }
        }

        if (folder.parentId == newParentId) return const Ok(null);

        final siblings = await _folders.getChildren(newParentId);
        final valid =
            siblings.flatMap((s) => validateFolderName(folder.name, s));
        if (valid case Err(:final failure)) return Err(failure);

        return _folders.moveFolder(folderId, newParentId);
    }
  }
}
