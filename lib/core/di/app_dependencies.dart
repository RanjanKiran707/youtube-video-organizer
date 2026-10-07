import 'package:http/http.dart' as http;
import 'package:youtube_saver/data/database/app_database.dart';
import 'package:youtube_saver/data/folder/folder_repository.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';
import 'package:youtube_saver/data/video/video_repository.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_repository.dart';
import 'package:youtube_saver/data/video_metadata/video_metadata_repository_interface.dart';
import 'package:youtube_saver/domain/use_cases/business/create_folder/create_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/delete_folder/delete_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/delete_video/delete_video_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/move_folder/move_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/move_video/move_video_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/rename_video/rename_video_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/reorder_folders/reorder_folders_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/reorder_videos/reorder_videos_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/save_shared_video_usecase.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:youtube_saver/domain/use_cases/ui/get_play_queue/get_play_queue_usecase.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_usecase.dart';

/// Everything global is built once, at startup, in this one place.
class AppDependencies {
  // Set once in main() before runApp. Tests can replace it.
  static late AppDependencies instance;

  // Business use cases.
  final SaveSharedVideoUsecase saveSharedVideo;
  final CreateFolderUsecase createFolder;
  final RenameFolderUsecase renameFolder;
  final RenameVideoUsecase renameVideo;
  final MoveFolderUsecase moveFolder;
  final MoveVideoUsecase moveVideo;
  final DeleteFolderUsecase deleteFolder;
  final DeleteVideoUsecase deleteVideo;
  final ReorderFoldersUsecase reorderFolders;
  final ReorderVideosUsecase reorderVideos;

  // UI use cases.
  final ListFolderContentsUsecase listFolderContents;
  final GetFolderPathUsecase getFolderPath;
  final GetPlayQueueUsecase getPlayQueue;

  AppDependencies._({
    required this.saveSharedVideo,
    required this.createFolder,
    required this.renameFolder,
    required this.renameVideo,
    required this.moveFolder,
    required this.moveVideo,
    required this.deleteFolder,
    required this.deleteVideo,
    required this.reorderFolders,
    required this.reorderVideos,
    required this.listFolderContents,
    required this.getFolderPath,
    required this.getPlayQueue,
  });

  /// The repositories can be replaced, so tests run against fakes.
  static Future<void> init({
    FolderRepositoryInterface? folderRepository,
    VideoRepositoryInterface? videoRepository,
    VideoMetadataRepositoryInterface? metadataRepository,
  }) async {
    // 1. Data layer (the only place that knows the real implementations).
    final database = (folderRepository == null || videoRepository == null)
        ? AppDatabase()
        : null;
    final FolderRepositoryInterface folders =
        folderRepository ?? FolderRepository(database!);
    final VideoRepositoryInterface videos =
        videoRepository ?? VideoRepository(database!);
    final VideoMetadataRepositoryInterface metadata =
        metadataRepository ?? VideoMetadataRepository(http.Client());

    // 2. Domain layer.
    instance = AppDependencies._(
      saveSharedVideo: SaveSharedVideoUsecase(videos, metadata),
      createFolder: CreateFolderUsecase(folders),
      renameFolder: RenameFolderUsecase(folders),
      renameVideo: RenameVideoUsecase(videos),
      moveFolder: MoveFolderUsecase(folders),
      moveVideo: MoveVideoUsecase(videos),
      deleteFolder: DeleteFolderUsecase(folders),
      deleteVideo: DeleteVideoUsecase(videos),
      reorderFolders: ReorderFoldersUsecase(folders),
      reorderVideos: ReorderVideosUsecase(videos),
      listFolderContents: ListFolderContentsUsecase(folders, videos),
      getFolderPath: GetFolderPathUsecase(folders),
      getPlayQueue: GetPlayQueueUsecase(videos),
    );
  }
}
