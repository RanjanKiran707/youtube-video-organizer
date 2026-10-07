# Progress: data

Models, repository interfaces and implementations, one folder per entity (`lib/data/`). Model: `docs/data_model.md`.

| Entity | Model | Interface | Implementation | Tests | Status |
|---|---|---|---|---|---|
| database | | | `database/app_database.dart` (+ generated `.g.dart`) | used by the tests below | Done |
| folder | `folder_model.dart` | `folder_repository_interface.dart` | `folder_repository.dart` | `test/data/folder_repository_test.dart` (8) | Done |
| video | `video_model.dart` | `video_repository_interface.dart` | `video_repository.dart` | `test/data/video_repository_test.dart` (8) | Done |
| video_metadata (oEmbed) | `video_metadata_model.dart` | `video_metadata_repository_interface.dart` | `video_metadata_repository.dart` | `test/data/video_metadata_repository_test.dart` (4) | Done |

`flutter analyze`: no issues. `flutter test`: 21 passed (including the default widget test).

## What is in place
- Drift database with `FOLDER` and `VIDEO` tables, `ON DELETE CASCADE` (foreign keys switched on in `beforeOpen`), library root = null parent.
- Folder repository: create, rename, delete (cascade), move, reorder, `getChildren`, `getPath` (breadcrumb), `watchChildren`.
- Video repository: add, rename, delete, move, reorder, `getVideos`, `watchVideos`.
- Position is assigned by the repository (appended at the end on create, add and move). The `position` in a passed model is ignored.
- oEmbed lookup returns `Err(NetworkFailure)` for offline, non-200 (private or deleted) and malformed responses.
- All repositories catch exceptions and return `Err`. `NetworkFailure` was added to `core/errors/failure.dart` because the save flow can continue with fallback data when the lookup fails.

## Decisions and gotchas
- `watch…` methods use `.map(...).transform(...)`, not an `async*` generator. Cancelling an `async*` generator hangs while it waits on the inner stream, which would block `ViewModel.dispose()`.
- Moving a folder into itself or a descendant is **not** checked here. The `move_folder` use case checks it with `getPath(newParentId)`.
- Sibling-unique folder names are **not** enforced here (SQLite unique indexes ignore NULL parents). The `create_folder` and `rename_folder` use cases check with `getChildren`.
- Folder item counts for the library list ("12 videos · 2 folders") are not a repository method yet. The `list_folder_contents` use case computes them from `getChildren` and `getVideos`, and a count query can be added if it is slow.
- Repositories are not yet created in `AppDependencies.init()`. They get wired together with the use cases in the domain step.

- `INTERNET` permission added to the main `AndroidManifest.xml` (it was only in the debug and profile manifests, so release builds had no network for oEmbed or the player).
- `reorderFolders` and `reorderVideos` update only the ids they are given. Checking that the list matches the current children exactly is done in the domain reorder use cases, not here.

## To do
- Wire `AppDatabase`, the repositories and an `http.Client` in `AppDependencies.init()` (with the domain step).
- `youtube_saver` Android: confirm the generated code builds in a release build (not yet run on a device).
