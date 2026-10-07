import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Folder tree. A null [parentId] means the library root.
@DataClassName('FolderRow')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get parentId =>
      text().nullable().references(Folders, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get position => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Saved videos. A null [folderId] means the library root.
@DataClassName('VideoRow')
class Videos extends Table {
  TextColumn get id => text()();
  TextColumn get folderId =>
      text().nullable().references(Folders, #id, onDelete: KeyAction.cascade)();
  TextColumn get youtubeVideoId => text()();
  TextColumn get title => text()();
  TextColumn get channelName => text()();
  TextColumn get thumbnailUrl => text()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get position => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Only the repositories in `data/` use this class.
@DriftDatabase(tables: [Folders, Videos])
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests (for example an in-memory database).
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'youtube_saver'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Needed for ON DELETE CASCADE.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
