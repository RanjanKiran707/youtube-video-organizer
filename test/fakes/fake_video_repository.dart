import 'dart:async';

import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/data/video/video_repository_interface.dart';

/// In-memory video repository for use case tests.
class FakeVideoRepository implements VideoRepositoryInterface {
  final List<VideoModel> videos = [];
  final _changes = StreamController<void>.broadcast(sync: true);

  /// Set to make every call return this failure.
  Failure? failWith;

  VideoModel add(String id, String? folderId, {String? title}) {
    final video = VideoModel(
      id: id,
      folderId: folderId,
      youtubeVideoId: 'yt$id',
      title: title ?? 'Video $id',
      channelName: 'Channel',
      thumbnailUrl: 'https://example.com/$id.jpg',
      durationSeconds: null,
      position: videos.where((v) => v.folderId == folderId).length,
      createdAt: DateTime(2026),
    );
    videos.add(video);
    _changes.add(null);
    return video;
  }

  VideoModel? byId(String id) {
    for (final v in videos) {
      if (v.id == id) return v;
    }
    return null;
  }

  List<VideoModel> _in(String? folderId) =>
      videos.where((v) => v.folderId == folderId).toList()
        ..sort((a, b) => a.position.compareTo(b.position));

  @override
  Future<Result<void>> addVideo(VideoModel video) async {
    if (failWith != null) return Err(failWith!);
    videos.add(video);
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> renameVideo(String videoId, String title) async {
    if (failWith != null) return Err(failWith!);
    final old = byId(videoId);
    if (old == null) return const Err(StorageFailure('video_not_found'));
    videos[videos.indexOf(old)] = _copy(old, title: title);
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteVideo(String videoId) async {
    if (failWith != null) return Err(failWith!);
    final old = byId(videoId);
    if (old == null) return const Err(StorageFailure('video_not_found'));
    videos.remove(old);
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> moveVideo(String videoId, String? newFolderId) async {
    if (failWith != null) return Err(failWith!);
    final old = byId(videoId);
    if (old == null) return const Err(StorageFailure('video_not_found'));
    videos[videos.indexOf(old)] = _copy(old, folderId: newFolderId);
    _changes.add(null);
    return const Ok(null);
  }

  /// Ids passed to the last successful `reorderVideos`.
  List<String>? reorderedTo;

  @override
  Future<Result<void>> reorderVideos(
    String? folderId,
    List<String> orderedVideoIds,
  ) async {
    if (failWith != null) return Err(failWith!);
    reorderedTo = orderedVideoIds;
    return const Ok(null);
  }

  @override
  Future<Result<List<VideoModel>>> getVideos(String? folderId) async {
    if (failWith != null) return Err(failWith!);
    return Ok(_in(folderId));
  }

  @override
  Stream<Result<List<VideoModel>>> watchVideos(String? folderId) {
    return Stream.multi((controller) {
      controller.add(_snapshot(folderId));
      final sub = _changes.stream.listen((_) {
        controller.add(_snapshot(folderId));
      });
      controller.onCancel = sub.cancel;
    });
  }

  VideoModel _copy(VideoModel v, {String? title, String? folderId}) =>
      VideoModel(
        id: v.id,
        folderId: folderId ?? v.folderId,
        youtubeVideoId: v.youtubeVideoId,
        title: title ?? v.title,
        channelName: v.channelName,
        thumbnailUrl: v.thumbnailUrl,
        durationSeconds: v.durationSeconds,
        position: v.position,
        createdAt: v.createdAt,
      );

  Result<List<VideoModel>> _snapshot(String? folderId) =>
      failWith != null ? Err(failWith!) : Ok(_in(folderId));
}
