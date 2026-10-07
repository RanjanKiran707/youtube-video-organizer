import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_usecase.dart';

class FolderBrowserData {
  /// Root first, the open folder last. Empty at the library root.
  final List<FolderModel> path;
  final ListFolderContentsReturnModel contents;

  const FolderBrowserData({required this.path, required this.contents});
}

/// Shows one folder live and can move to another. Shared by the library screen
/// (one folder per screen) and the folder picker (moves in place).
class FolderBrowserController {
  final ListFolderContentsUsecase _listContents;
  final GetFolderPathUsecase _getPath;

  final ValueNotifier<ViewState<FolderBrowserData>> state = ValueNotifier(
    const ViewStateLoading(),
  );

  String? _folderId;
  StreamSubscription<Result<ListFolderContentsReturnModel>>? _subscription;
  int _token = 0; // a newer open() or dispose() makes older ones stop

  FolderBrowserController({
    required ListFolderContentsUsecase listContents,
    required GetFolderPathUsecase getPath,
    String? initialFolderId,
  }) : _listContents = listContents,
       _getPath = getPath {
    open(initialFolderId);
  }

  /// The open folder, null = library root.
  String? get folderId => _folderId;

  Future<void> open(String? folderId) async {
    final token = ++_token;
    _folderId = folderId;
    // Events stop as soon as cancel() is called, so its future is not awaited.
    _subscription?.cancel();
    _subscription = null;

    state.value = const ViewStateLoading();
    final path = await _getPath(folderId);
    if (token != _token) return;

    switch (path) {
      case Err(:final failure):
        state.value = ViewStateError(failure);
      case Ok(value: final folders):
        _subscription = _listContents(folderId).listen((result) {
          state.value = result.fold<ViewState<FolderBrowserData>>(
            (failure) => ViewStateError(failure),
            (contents) => ViewStateLoaded(
              FolderBrowserData(path: folders, contents: contents),
            ),
          );
        });
    }
  }

  void dispose() {
    _token++; // cancel first, so nothing arrives after dispose
    _subscription?.cancel();
    state.dispose();
  }
}
