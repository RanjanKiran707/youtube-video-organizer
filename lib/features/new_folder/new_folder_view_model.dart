import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/domain/use_cases/business/create_folder/create_folder_argument_model.dart';
import 'package:youtube_saver/domain/use_cases/business/create_folder/create_folder_usecase.dart';

class NewFolderBundle {
  final String? parentId; // null = library root
  const NewFolderBundle({this.parentId});
}

class NewFolderViewModel {
  final NewFolderBundle bundle;
  final CreateFolderUsecase _createFolder;

  /// State of the create action.
  final ValueNotifier<ViewState<void>> createState = ValueNotifier(
    const ViewStateIdle(),
  );

  NewFolderViewModel({
    required this.bundle,
    required CreateFolderUsecase createFolder,
  }) : _createFolder = createFolder;

  Future<void> onCreate(String name) async {
    if (createState.value.isLoading) return; // blocking rule: ignore re-entry

    createState.value = const ViewStateLoading();

    final result = await _createFolder(
      CreateFolderArgumentModel(
        folderId: const Uuid().v4(),
        parentId: bundle.parentId,
        name: name,
      ),
    );

    createState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
  }

  void dispose() {
    createState.dispose();
  }
}
