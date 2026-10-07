import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';

class ReorderFoldersUsecase {
  final FolderRepositoryInterface _folders;

  ReorderFoldersUsecase(this._folders);

  /// [orderedFolderIds] must list every folder in [parentId] exactly once.
  /// Anything else would leave stale positions behind, so it is rejected.
  Future<Result<void>> call(
    String? parentId,
    List<String> orderedFolderIds,
  ) async {
    final children = await _folders.getChildren(parentId);
    switch (children) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final current = value.map((f) => f.id).toSet();
        final given = orderedFolderIds.toSet();
        if (given.length != orderedFolderIds.length ||
            given.length != current.length ||
            !given.containsAll(current)) {
          return const Err(ValidationFailure('reorder_mismatch'));
        }
        return _folders.reorderFolders(parentId, orderedFolderIds);
    }
  }
}
