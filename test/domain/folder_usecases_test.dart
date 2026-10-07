import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/domain/use_cases/business/create_folder/create_folder_argument_model.dart';
import 'package:youtube_saver/domain/use_cases/business/create_folder/create_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/move_folder/move_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';
import 'package:youtube_saver/domain/use_cases/business/reorder_folders/reorder_folders_usecase.dart';

import '../fakes/fake_folder_repository.dart';

String? _validation(Result<void> r) => switch (r) {
      Err(failure: ValidationFailure(:final message)) => message,
      _ => null,
    };

void main() {
  late FakeFolderRepository folders;

  setUp(() => folders = FakeFolderRepository());

  group('CreateFolderUsecase', () {
    CreateFolderArgumentModel arg(String name, {String? parent}) =>
        CreateFolderArgumentModel(folderId: 'new', parentId: parent, name: name);

    test('creates the folder with a trimmed name', () async {
      final result = await CreateFolderUsecase(folders)(arg('  Music  '));

      expect(result, isA<Ok<void>>());
      expect(folders.byId('new')!.name, 'Music');
    });

    test('rejects an empty name', () async {
      final result = await CreateFolderUsecase(folders)(arg('   '));

      expect(_validation(result), 'name_required');
      expect(folders.folders, isEmpty);
    });

    test('rejects a name over the limit', () async {
      final result = await CreateFolderUsecase(folders)(arg('a' * 61));

      expect(_validation(result), 'name_too_long');
    });

    test('rejects a duplicate name among siblings, ignoring case', () async {
      folders.add('a', null, 'Music');

      final result = await CreateFolderUsecase(folders)(arg('music'));

      expect(_validation(result), 'name_taken');
    });

    test('allows the same name under a different parent', () async {
      folders.add('a', null, 'Music');
      folders.add('p', null, 'Other');

      final result = await CreateFolderUsecase(folders)(arg('Music', parent: 'p'));

      expect(result, isA<Ok<void>>());
    });

    test('passes a storage failure through', () async {
      folders.failWith = const StorageFailure('boom');

      final result = await CreateFolderUsecase(folders)(arg('Music'));

      expect((result as Err).failure, isA<StorageFailure>());
    });
  });

  group('RenameFolderUsecase', () {
    test('renames, and the folder may keep its own name in another case', () async {
      folders.add('a', null, 'music');

      final result = await RenameFolderUsecase(folders)('a', 'Music');

      expect(result, isA<Ok<void>>());
      expect(folders.byId('a')!.name, 'Music');
    });

    test('rejects a name used by a sibling', () async {
      folders.add('a', null, 'Music');
      folders.add('b', null, 'Talks');

      final result = await RenameFolderUsecase(folders)('b', 'Music');

      expect(_validation(result), 'name_taken');
      expect(folders.byId('b')!.name, 'Talks');
    });

    test('an unknown folder is an Err', () async {
      final result = await RenameFolderUsecase(folders)('nope', 'Music');

      expect(result, isA<Err<void>>());
    });
  });

  group('MoveFolderUsecase', () {
    test('moves a folder to another parent', () async {
      folders.add('a', null, 'A');
      folders.add('b', null, 'B');

      final result = await MoveFolderUsecase(folders)('a', 'b');

      expect(result, isA<Ok<void>>());
      expect(folders.byId('a')!.parentId, 'b');
    });

    test('moves a folder to the library root', () async {
      folders.add('b', null, 'B');
      folders.add('a', 'b', 'A');

      final result = await MoveFolderUsecase(folders)('a', null);

      expect(result, isA<Ok<void>>());
      expect(folders.byId('a')!.parentId, isNull);
    });

    test('rejects a move into itself', () async {
      folders.add('a', null, 'A');

      final result = await MoveFolderUsecase(folders)('a', 'a');

      expect(_validation(result), 'move_into_itself');
    });

    test('rejects a move into a descendant', () async {
      folders.add('a', null, 'A');
      folders.add('b', 'a', 'B');
      folders.add('c', 'b', 'C');

      final result = await MoveFolderUsecase(folders)('a', 'c');

      expect(_validation(result), 'move_into_itself');
      expect(folders.byId('a')!.parentId, isNull);
    });

    test('rejects a move that would clash with a sibling name', () async {
      folders.add('a', null, 'Music');
      folders.add('p', null, 'P');
      folders.add('x', 'p', 'music');

      final result = await MoveFolderUsecase(folders)('a', 'p');

      expect(_validation(result), 'name_taken');
    });

    test('moving to the current parent does nothing', () async {
      folders.add('a', null, 'A');

      final result = await MoveFolderUsecase(folders)('a', null);

      expect(result, isA<Ok<void>>());
    });
  });

  group('ReorderFoldersUsecase', () {
    setUp(() {
      folders.add('a', null, 'A');
      folders.add('b', null, 'B');
      folders.add('c', null, 'C');
    });

    test('accepts a full permutation', () async {
      final result = await ReorderFoldersUsecase(folders)(null, ['c', 'a', 'b']);

      expect(result, isA<Ok<void>>());
      expect(folders.reorderedTo, ['c', 'a', 'b']);
    });

    test('rejects a list that leaves a sibling out', () async {
      final result = await ReorderFoldersUsecase(folders)(null, ['c', 'a']);

      expect(_validation(result), 'reorder_mismatch');
      expect(folders.reorderedTo, isNull);
    });

    test('rejects a duplicate id', () async {
      final result = await ReorderFoldersUsecase(folders)(null, ['a', 'a', 'b']);

      expect(_validation(result), 'reorder_mismatch');
    });

    test('rejects an id from another parent', () async {
      folders.add('x', 'a', 'X');

      final result = await ReorderFoldersUsecase(folders)(null, ['a', 'b', 'x']);

      expect(_validation(result), 'reorder_mismatch');
    });
  });
}
