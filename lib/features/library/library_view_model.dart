import 'package:flutter/foundation.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/domain/use_cases/business/delete_folder/delete_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/delete_video/delete_video_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/move_folder/move_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/move_video/move_video_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/rename_video/rename_video_usecase.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_usecase.dart';
import 'package:youtube_saver/features/shared/folder_browser_controller.dart';

class LibraryBundle {
  final String? folderId; // null = library root
  const LibraryBundle({this.folderId});
}

class LibraryViewModel {
  final LibraryBundle bundle;
  final FolderBrowserController browser;

  final RenameFolderUsecase _renameFolder;
  final RenameVideoUsecase _renameVideo;
  final DeleteFolderUsecase _deleteFolder;
  final DeleteVideoUsecase _deleteVideo;
  final MoveFolderUsecase _moveFolder;
  final MoveVideoUsecase _moveVideo;

  /// State of the rename and delete actions. A failure is shown once, then the
  /// next action starts from `Loading` again.
  final ValueNotifier<ViewState<void>> actionState = ValueNotifier(
    const ViewStateIdle(),
  );

  LibraryViewModel({
    required this.bundle,
    required ListFolderContentsUsecase listFolderContents,
    required GetFolderPathUsecase getFolderPath,
    required RenameFolderUsecase renameFolder,
    required RenameVideoUsecase renameVideo,
    required DeleteFolderUsecase deleteFolder,
    required DeleteVideoUsecase deleteVideo,
    required MoveFolderUsecase moveFolder,
    required MoveVideoUsecase moveVideo,
  }) : browser = FolderBrowserController(
         listContents: listFolderContents,
         getPath: getFolderPath,
         initialFolderId: bundle.folderId,
       ),
       _renameFolder = renameFolder,
       _renameVideo = renameVideo,
       _deleteFolder = deleteFolder,
       _deleteVideo = deleteVideo,
       _moveFolder = moveFolder,
       _moveVideo = moveVideo;

  Future<void> renameFolder(String folderId, String name) =>
      _run(() => _renameFolder(folderId, name));

  Future<void> renameVideo(String videoId, String title) =>
      _run(() => _renameVideo(videoId, title));

  Future<void> deleteFolder(String folderId) =>
      _run(() => _deleteFolder(folderId));

  Future<void> deleteVideo(String videoId) => _run(() => _deleteVideo(videoId));

  /// Move runs inside the folder picker, which blocks itself while it runs,
  /// so these return the result instead of using [actionState].
  Future<Result<void>> moveFolder(String folderId, String? newParentId) =>
      _moveFolder(folderId, newParentId);

  Future<Result<void>> moveVideo(String videoId, String? newFolderId) =>
      _moveVideo(videoId, newFolderId);

  Future<void> _run(Future<Result<void>> Function() action) async {
    if (actionState.value.isLoading) return; // blocking rule: ignore re-entry

    actionState.value = const ViewStateLoading();
    final result = await action();
    actionState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
  }

  void dispose() {
    browser.dispose();
    actionState.dispose();
  }
}
