import 'package:flutter/foundation.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_usecase.dart';
import 'package:youtube_saver/features/shared/folder_browser_controller.dart';

/// Chooses a folder and runs [onConfirm] on it ("Save to" after a share,
/// "Move to" from the library). The picker stays blocked while it runs.
class FolderPickerBundle {
  final String title;
  final String confirmVerb; // "Save" or "Move"
  final Future<Result<void>> Function(String? folderId) onConfirm;

  /// A folder that cannot be chosen or entered (the one being moved).
  final String? excludeFolderId;
  final String? initialFolderId;

  /// Shown above the list, for the shared video.
  final String? previewThumbnailUrl;
  final String? previewText;

  const FolderPickerBundle({
    required this.title,
    required this.confirmVerb,
    required this.onConfirm,
    this.excludeFolderId,
    this.initialFolderId,
    this.previewThumbnailUrl,
    this.previewText,
  });
}

class FolderPickerViewModel {
  final FolderPickerBundle bundle;
  final FolderBrowserController browser;

  /// State of the confirm action.
  final ValueNotifier<ViewState<void>> confirmState = ValueNotifier(
    const ViewStateIdle(),
  );

  FolderPickerViewModel({
    required this.bundle,
    required ListFolderContentsUsecase listFolderContents,
    required GetFolderPathUsecase getFolderPath,
  }) : browser = FolderBrowserController(
         listContents: listFolderContents,
         getPath: getFolderPath,
         initialFolderId: bundle.initialFolderId,
       );

  bool get atRoot => browser.folderId == null;

  void open(String? folderId) {
    if (confirmState.value.isLoading) return;
    confirmState.value = const ViewStateIdle();
    browser.open(folderId);
  }

  /// Goes to the parent of the open folder.
  void up() {
    final current = browser.state.value;
    if (current is! ViewStateLoaded<FolderBrowserData>) {
      open(null);
      return;
    }
    final path = current.data.path;
    open(path.length >= 2 ? path[path.length - 2].id : null);
  }

  Future<void> confirm() async {
    if (confirmState.value.isLoading) return; // blocking rule: ignore re-entry
    if (browser.state.value is! ViewStateLoaded<FolderBrowserData>) return;

    confirmState.value = const ViewStateLoading();
    final result = await bundle.onConfirm(browser.folderId);
    confirmState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
  }

  void dispose() {
    browser.dispose();
    confirmState.dispose();
  }
}
