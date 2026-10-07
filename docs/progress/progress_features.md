# Progress: features

One View + ViewModel per screen (`lib/features/`). Designs: `project_spec/mockup.html`.

| Feature | Mockup screen | Files | Tests | Status |
|---|---|---|---|---|
| `library` (root and folder view, play all, rename / move / delete menus, empty state, new folder button) | 1, 4, 7 | `library/` | `test/features/folder_features_test.dart`, `test/widget_test.dart` | Done |
| `folder_picker` (share target, navigate, "Save to X"; also "Move to X") | 2 | `folder_picker/` | `folder_features_test.dart`, `widget_test.dart` | Done |
| `new_folder` dialog | 3 | `new_folder/` | `folder_features_test.dart`, `widget_test.dart` | Done |
| `player` (embed, up next, auto-advance, can't-embed fallback, queue end) | 5, 6, end note | `player/` | `test/features/player_view_model_test.dart` (ViewModel only) | Done, not run on a device |
| `app` (theme, share listener, home = library) | n/a | `app/` | `widget_test.dart` (share flow) | Done |

`flutter analyze`: no issues. `flutter test`: 95 passed. `flutter build apk --debug`: builds.

## Notes
- `features/shared/` holds what the screens share: `FolderBrowserController` (live folder contents + breadcrumb), `messageFor(Failure)`, and small widgets (folder and video tiles, breadcrumb, text dialog).
- The folder picker is one screen used two ways. Its bundle carries an `onConfirm` function, so "Save to" (share) and "Move to" (library) share the screen, and it stays blocked while that runs (guide 7.1).
- The Android share intent filter (`text/plain`) is in the manifest, and the activity is `singleTask` so a share while the app is open reaches the running app.
- End of folder: playback stops and "Queue finished" is shown (the spec leaves this open).
- A video that can't be embedded is marked, shows "Open in YouTube", and is skipped while auto-advance is on.

## Known gaps
- The player View is not widget-tested (it needs a WebView). The ViewModel is. It has not been run on a device, so the real YouTube error and ended events are unconfirmed.
- The share preview shows the video's thumbnail and the shared text, not the title (the title is looked up when saving).
- Reordering has use cases but no screen yet.
- No dark/light switch beyond following the system.
- `android/build.gradle.kts` forces Java 17 for `receive_sharing_intent` (its Java and Kotlin targets disagreed and failed `flutter run`).
