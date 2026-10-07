import 'dart:async';

import 'package:drift/drift.dart';
import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/database/app_database.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';

class VideoRepository implements VideoRepositoryInterface {
  final AppDatabase _db;

  VideoRepository(this._db);

  @override
  Future<Result<void>> addVideo(VideoModel video) async {
    try {
      await _db.transaction(() async {
        final position = await _nextPosition(video.folderId);
        await _db.into(_db.videos).insert(
              VideosCompanion.insert(
                id: video.id,
                folderId: Value(video.folderId),
                youtubeVideoId: video.youtubeVideoId,
                title: video.title,
                channelName: video.channelName,
                thumbnailUrl: video.thumbnailUrl,
                durationSeconds: Value(video.durationSeconds),
                position: position,
                createdAt: video.createdAt.millisecondsSinceEpoch,
              ),
            );
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> renameVideo(String videoId, String title) async {
    try {
      final updated = await (_db.update(_db.videos)
            ..where((v) => v.id.equals(videoId)))
          .write(VideosCompanion(title: Value(title)));
      if (updated == 0) return const Err(StorageFailure('video_not_found'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteVideo(String videoId) async {
    try {
      final deleted = await (_db.delete(_db.videos)
            ..where((v) => v.id.equals(videoId)))
          .go();
      if (deleted == 0) return const Err(StorageFailure('video_not_found'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> moveVideo(String videoId, String? newFolderId) async {
    try {
      final updated = await _db.transaction(() async {
        final position = await _nextPosition(newFolderId);
        return (_db.update(_db.videos)..where((v) => v.id.equals(videoId)))
            .write(VideosCompanion(
          folderId: Value(newFolderId),
          position: Value(position),
        ));
      });
      if (updated == 0) return const Err(StorageFailure('video_not_found'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> reorderVideos(
    String? folderId,
    List<String> orderedVideoIds,
  ) async {
    try {
      await _db.transaction(() async {
        for (var i = 0; i < orderedVideoIds.length; i++) {
          await (_db.update(_db.videos)
                ..where((v) =>
                    v.id.equals(orderedVideoIds[i]) & _folderIs(v, folderId)))
              .write(VideosCompanion(position: Value(i)));
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<VideoModel>>> getVideos(String? folderId) async {
    try {
      final rows = await _videosQuery(folderId).get();
      return Ok(rows.map(_toModel).toList());
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Stream<Result<List<VideoModel>>> watchVideos(String? folderId) {
    // Not an `async*` generator: cancelling one hangs while it waits on the
    // inner stream, which would block ViewModel.dispose().
    return _videosQuery(folderId)
        .watch()
        .map<Result<List<VideoModel>>>((rows) => Ok(rows.map(_toModel).toList()))
        .transform(StreamTransformer.fromHandlers(
      handleError: (error, _, sink) => sink.add(Err(StorageFailure('$error'))),
    ));
  }

  SimpleSelectStatement<$VideosTable, VideoRow> _videosQuery(
    String? folderId,
  ) =>
      _db.select(_db.videos)
        ..where((v) => _folderIs(v, folderId))
        ..orderBy([(v) => OrderingTerm.asc(v.position)]);

  Expression<bool> _folderIs(Videos v, String? folderId) =>
      folderId == null ? v.folderId.isNull() : v.folderId.equals(folderId);

  Future<int> _nextPosition(String? folderId) async {
    final maxPosition = _db.videos.position.max();
    final query = _db.selectOnly(_db.videos)
      ..addColumns([maxPosition])
      ..where(_folderIs(_db.videos, folderId));
    final current = await query.map((r) => r.read(maxPosition)).getSingle();
    return (current ?? -1) + 1;
  }

  VideoModel _toModel(VideoRow row) => VideoModel(
        id: row.id,
        folderId: row.folderId,
        youtubeVideoId: row.youtubeVideoId,
        title: row.title,
        channelName: row.channelName,
        thumbnailUrl: row.thumbnailUrl,
        durationSeconds: row.durationSeconds,
        position: row.position,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );
}
