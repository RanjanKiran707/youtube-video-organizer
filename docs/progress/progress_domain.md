# Progress: domain

Use cases only (`lib/domain/use_cases/`). Depends on the data repository interfaces. All are wired in `AppDependencies.init()`.

| Use case | Kind | Tests | Status |
|---|---|---|---|
| `save_shared_video` (+ `youtube_url_parser.dart`, argument model) | Business | `test/domain/video_usecases_test.dart` | Done |
| `create_folder` (+ argument model) | Business | `test/domain/folder_usecases_test.dart` | Done |
| `rename_folder` | Business | `folder_usecases_test.dart` | Done |
| `rename_video` | Business | `video_usecases_test.dart` | Done |
| `move_folder` (rejects a move into itself or a descendant) | Business | `folder_usecases_test.dart` | Done |
| `move_video` (pass-through) | Business | not tested (no logic) | Done |
| `delete_folder`, `delete_video` (pass-through) | Business | not tested (no logic) | Done |
| `reorder_folders`, `reorder_videos` | Business | `folder_usecases_test.dart`, `video_usecases_test.dart` | Done |
| `list_folder_contents` (live folders with counts + videos) | UI | `test/domain/ui_usecases_test.dart` | Done |
| `get_folder_path` (breadcrumb) | UI | `ui_usecases_test.dart` | Done |
| `get_play_queue` (direct videos, `indexOf` for the start video) | UI | `ui_usecases_test.dart` | Done |

`flutter analyze`: no issues. `flutter test`: 60 passed. Fakes (no mocking package) are in `test/fakes/`.

## Rules the use cases enforce
- Folder names are trimmed, 1 to 60 characters, and unique among siblings (case-insensitive). Shared by create, rename and move (`business/shared/folder_name_rules.dart`).
- A folder cannot be moved into itself or a descendant, and it cannot move to a parent that already has a folder with the same name.
- `reorder_*` must be given every child exactly once. A missing, duplicate or foreign id returns `ValidationFailure('reorder_mismatch')`. This closes the gap noted in `progress_data.md`.
- `save_shared_video` finds the first YouTube video link in the shared text (`youtu.be`, `watch?v=`, `shorts`, `embed`, `live`; playlist and channel links are rejected with `not_a_youtube_video`). If the oEmbed lookup fails the video is still saved, titled "YouTube video" with the standard `i.ytimg.com` thumbnail, so a share is never lost. The user can rename it.

## Notes
- Business and UI use cases are split into `business/` and `ui/` folders, as in guide section 6.3.1. No UI use case calls a business use case.
- `list_folder_contents` re-emits when a direct child changes. A change deeper down (a video added inside a subfolder) shows in that subfolder's count only the next time the list emits.
- The ViewModel generates ids (as `AddStudentViewModel` does in the guide), so use cases stay deterministic. `uuid` is used there.
- Not checked: saving the same YouTube video twice into one folder (the data model allows it).
- Failure messages used by the UI to choose text: `name_required`, `name_too_long`, `name_taken`, `title_required`, `move_into_itself`, `reorder_mismatch`, `not_a_youtube_video`.
