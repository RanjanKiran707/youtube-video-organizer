import 'dart:async';

import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';

/// In-memory folder repository for use case tests.
class FakeFolderRepository implements FolderRepositoryInterface {
  final List<FolderModel> folders = [];
  final _changes = StreamController<void>.broadcast(sync: true);

  /// Set to make every call return this failure.
  Failure? failWith;

  FolderModel add(String id, String? parentId, String name) {
    final folder = FolderModel(
      id: id,
      parentId: parentId,
      name: name,
      position: folders.where((f) => f.parentId == parentId).length,
      createdAt: DateTime(2026),
    );
    folders.add(folder);
    _changes.add(null);
    return folder;
  }

  FolderModel? byId(String id) {
    for (final f in folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<FolderModel> _children(String? parentId) =>
      folders.where((f) => f.parentId == parentId).toList()
        ..sort((a, b) => a.position.compareTo(b.position));

  @override
  Future<Result<void>> createFolder(FolderModel folder) async {
    if (failWith != null) return Err(failWith!);
    add(folder.id, folder.parentId, folder.name);
    return const Ok(null);
  }

  @override
  Future<Result<void>> renameFolder(String folderId, String name) async {
    if (failWith != null) return Err(failWith!);
    final old = byId(folderId);
    if (old == null) return const Err(StorageFailure('folder_not_found'));
    folders[folders.indexOf(old)] = FolderModel(
      id: old.id,
      parentId: old.parentId,
      name: name,
      position: old.position,
      createdAt: old.createdAt,
    );
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteFolder(String folderId) async {
    if (failWith != null) return Err(failWith!);
    final old = byId(folderId);
    if (old == null) return const Err(StorageFailure('folder_not_found'));
    folders.remove(old);
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> moveFolder(String folderId, String? newParentId) async {
    if (failWith != null) return Err(failWith!);
    final old = byId(folderId);
    if (old == null) return const Err(StorageFailure('folder_not_found'));
    folders[folders.indexOf(old)] = FolderModel(
      id: old.id,
      parentId: newParentId,
      name: old.name,
      position: _children(newParentId).length,
      createdAt: old.createdAt,
    );
    _changes.add(null);
    return const Ok(null);
  }

  /// Ids passed to the last successful `reorderFolders`.
  List<String>? reorderedTo;

  @override
  Future<Result<void>> reorderFolders(
    String? parentId,
    List<String> orderedFolderIds,
  ) async {
    if (failWith != null) return Err(failWith!);
    reorderedTo = orderedFolderIds;
    return const Ok(null);
  }

  @override
  Future<Result<List<FolderModel>>> getChildren(String? parentId) async {
    if (failWith != null) return Err(failWith!);
    return Ok(_children(parentId));
  }

  @override
  Future<Result<List<FolderModel>>> getPath(String folderId) async {
    if (failWith != null) return Err(failWith!);
    final path = <FolderModel>[];
    String? current = folderId;
    while (current != null) {
      final folder = byId(current);
      if (folder == null) return const Err(StorageFailure('folder_not_found'));
      path.insert(0, folder);
      current = folder.parentId;
    }
    return Ok(path);
  }

  @override
  Stream<Result<List<FolderModel>>> watchChildren(String? parentId) {
    return Stream.multi((controller) {
      controller.add(_snapshot(parentId));
      final sub = _changes.stream.listen((_) {
        controller.add(_snapshot(parentId));
      });
      controller.onCancel = sub.cancel;
    });
  }

  Result<List<FolderModel>> _snapshot(String? parentId) =>
      failWith != null ? Err(failWith!) : Ok(_children(parentId));
}
