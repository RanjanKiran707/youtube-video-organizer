import 'dart:async';

import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';

/// Live contents of one folder (null = library root): its subfolders with item
/// counts, then its videos. Emits again when a direct child is added, removed,
/// renamed or reordered. A change deeper down only shows in the counts the next
/// time this folder emits.
class ListFolderContentsUsecase {
  final FolderRepositoryInterface _folders;
  final VideoRepositoryInterface _videos;

  ListFolderContentsUsecase(this._folders, this._videos);

  Stream<Result<ListFolderContentsReturnModel>> call(String? folderId) {
    late final StreamController<Result<ListFolderContentsReturnModel>> out;
    StreamSubscription<Result<List<FolderModel>>>? folderSub;
    StreamSubscription<Result<List<VideoModel>>>? videoSub;
    Result<List<FolderModel>>? latestFolders;
    Result<List<VideoModel>>? latestVideos;
    var generation = 0; // drops results of a lookup that a newer event replaced

    Future<void> emit() async {
      final folders = latestFolders;
      final videos = latestVideos;
      if (folders == null || videos == null) return;
      final mine = ++generation;

      final Result<ListFolderContentsReturnModel> result;
      switch ((folders, videos)) {
        case (Err(:final failure), _):
          result = Err(failure);
        case (_, Err(:final failure)):
          result = Err(failure);
        case (Ok(value: final f), Ok(value: final v)):
          result = await _withCounts(f, v);
      }
      if (mine == generation && !out.isClosed) out.add(result);
    }

    out = StreamController<Result<ListFolderContentsReturnModel>>(
      onListen: () {
        folderSub = _folders.watchChildren(folderId).listen((r) {
          latestFolders = r;
          emit();
        });
        videoSub = _videos.watchVideos(folderId).listen((r) {
          latestVideos = r;
          emit();
        });
      },
      onCancel: () async {
        generation++;
        await Future.wait([
          if (folderSub != null) folderSub!.cancel(),
          if (videoSub != null) videoSub!.cancel(),
        ]);
      },
    );
    return out.stream;
  }

  Future<Result<ListFolderContentsReturnModel>> _withCounts(
    List<FolderModel> folders,
    List<VideoModel> videos,
  ) async {
    final items = <FolderItem>[];
    for (final folder in folders) {
      final children = await _folders.getChildren(folder.id);
      final inside = await _videos.getVideos(folder.id);
      switch ((children, inside)) {
        case (Err(:final failure), _):
          return Err(failure);
        case (_, Err(:final failure)):
          return Err(failure);
        case (Ok(value: final c), Ok(value: final v)):
          items.add(FolderItem(
            id: folder.id,
            name: folder.name,
            folderCount: c.length,
            videoCount: v.length,
          ));
      }
    }
    return Ok(ListFolderContentsReturnModel(folders: items, videos: videos));
  }
}
