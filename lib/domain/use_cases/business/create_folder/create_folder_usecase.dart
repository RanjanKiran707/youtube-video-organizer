import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';
import 'package:youtube_saver/domain/use_cases/business/create_folder/create_folder_argument_model.dart';
import 'package:youtube_saver/domain/use_cases/business/shared/folder_name_rules.dart';

class CreateFolderUsecase {
  final FolderRepositoryInterface _folders;
  final DateTime Function() _now;

  CreateFolderUsecase(this._folders, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  Future<Result<void>> call(CreateFolderArgumentModel model) async {
    final siblings = await _folders.getChildren(model.parentId);
    final name = siblings.flatMap((s) => validateFolderName(model.name, s));

    switch (name) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        return _folders.createFolder(
          FolderModel(
            id: model.folderId,
            parentId: model.parentId,
            name: value,
            position: 0, // the repository appends it at the end
            createdAt: _now(),
          ),
        );
    }
  }
}
