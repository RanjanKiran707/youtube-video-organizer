import 'dart:async';

import 'package:drift/drift.dart';
import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/database/app_database.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';
import 'package:youtube_saver/data/folder/folder_repository_interface.dart';

class FolderRepository implements FolderRepositoryInterface {
  final AppDatabase _db;

  FolderRepository(this._db);

  @override
  Future<Result<void>> createFolder(FolderModel folder) async {
    try {
      await _db.transaction(() async {
        final position = await _nextPosition(folder.parentId);
        await _db.into(_db.folders).insert(
              FoldersCompanion.insert(
                id: folder.id,
                parentId: Value(folder.parentId),
                name: folder.name,
                position: position,
                createdAt: folder.createdAt.millisecondsSinceEpoch,
              ),
            );
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> renameFolder(String folderId, String name) async {
    try {
      final updated = await (_db.update(_db.folders)
            ..where((f) => f.id.equals(folderId)))
          .write(FoldersCompanion(name: Value(name)));
      if (updated == 0) return const Err(StorageFailure('folder_not_found'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFolder(String folderId) async {
    try {
      // Subfolders and videos go with it (ON DELETE CASCADE).
      final deleted = await (_db.delete(_db.folders)
            ..where((f) => f.id.equals(folderId)))
          .go();
      if (deleted == 0) return const Err(StorageFailure('folder_not_found'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> moveFolder(String folderId, String? newParentId) async {
    try {
      final updated = await _db.transaction(() async {
        final position = await _nextPosition(newParentId);
        return (_db.update(_db.folders)..where((f) => f.id.equals(folderId)))
            .write(FoldersCompanion(
          parentId: Value(newParentId),
          position: Value(position),
        ));
      });
      if (updated == 0) return const Err(StorageFailure('folder_not_found'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> reorderFolders(
    String? parentId,
    List<String> orderedFolderIds,
  ) async {
    try {
      await _db.transaction(() async {
        for (var i = 0; i < orderedFolderIds.length; i++) {
          await (_db.update(_db.folders)
                ..where((f) =>
                    f.id.equals(orderedFolderIds[i]) & _parentIs(f, parentId)))
              .write(FoldersCompanion(position: Value(i)));
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<FolderModel>>> getChildren(String? parentId) async {
    try {
      final rows = await _childrenQuery(parentId).get();
      return Ok(rows.map(_toModel).toList());
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<FolderModel>>> getPath(String folderId) async {
    try {
      final path = <FolderModel>[];
      String? currentId = folderId;
      while (currentId != null) {
        final row = await (_db.select(_db.folders)
              ..where((f) => f.id.equals(currentId!)))
            .getSingleOrNull();
        if (row == null) return const Err(StorageFailure('folder_not_found'));
        path.insert(0, _toModel(row));
        currentId = row.parentId;
      }
      return Ok(path);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Stream<Result<List<FolderModel>>> watchChildren(String? parentId) {
    // Not an `async*` generator: cancelling one hangs while it waits on the
    // inner stream, which would block ViewModel.dispose().
    return _childrenQuery(parentId)
        .watch()
        .map<Result<List<FolderModel>>>((rows) => Ok(rows.map(_toModel).toList()))
        .transform(StreamTransformer.fromHandlers(
      handleError: (error, _, sink) => sink.add(Err(StorageFailure('$error'))),
    ));
  }

  SimpleSelectStatement<$FoldersTable, FolderRow> _childrenQuery(
    String? parentId,
  ) =>
      _db.select(_db.folders)
        ..where((f) => _parentIs(f, parentId))
        ..orderBy([(f) => OrderingTerm.asc(f.position)]);

  Expression<bool> _parentIs(Folders f, String? parentId) =>
      parentId == null ? f.parentId.isNull() : f.parentId.equals(parentId);

  Future<int> _nextPosition(String? parentId) async {
    final maxPosition = _db.folders.position.max();
    final query = _db.selectOnly(_db.folders)
      ..addColumns([maxPosition])
      ..where(_parentIs(_db.folders, parentId));
    final current = await query.map((r) => r.read(maxPosition)).getSingle();
    return (current ?? -1) + 1;
  }

  FolderModel _toModel(FolderRow row) => FolderModel(
        id: row.id,
        parentId: row.parentId,
        name: row.name,
        position: row.position,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );
}
