# Dependencies (proposed, awaiting approval)

App name: `youtube_saver`. Android only. Nothing here duplicates what `flutter_arch_general.md` already provides (Result, ViewState, `ValueNotifier` state, hand-wired DI).

## Runtime

| Package | Purpose | Spec requirement |
|---|---|---|
| `receive_sharing_intent` | Receives the `ACTION_SEND` `text/plain` share from the YouTube app (both cold start and while the app is open) and hands the URL to Dart. Avoids writing custom Kotlin. | 1. Share-to-app |
| `youtube_player_iframe` | Plays videos with the official YouTube IFrame Player API in a WebView. Exposes `onStateChange` (ended) and error codes (101/150, private/deleted). Within YouTube's ToS. | 3. In-app playback, 4. Auto-advance |
| `drift` | Local SQLite with typed queries and `watch*` streams, which fit the `Stream<Result<T>>` repository rule. Used only inside `data/`. | 2. Folders, local storage |
| `drift_flutter` | Opens the drift database on Android (bundles SQLite, resolves the DB path). | 2. Folders |
| `http` | Calls YouTube's oEmbed endpoint for title, channel and thumbnail. No API key. | 1. Share-to-app |
| `url_launcher` | "Open in YouTube" fallback for videos that can't be embedded. | 3. In-app playback |
| `uuid` | Generates ids for folders and videos. | 2. Folders |
| `cached_network_image` | Caches thumbnails so lists render offline after the first load. | UI (mockup lists) |

## Dev

| Package | Purpose |
|---|---|
| `drift_dev` | Generates drift code. |
| `build_runner` | Runs the drift generator. |
| `flutter_lints` | Added by `flutter create`. |
| `integration_test` | From the Flutter SDK, for key-journey tests. Not a pub.dev add. |

## Deliberately not added

- State management or DI packages: the arch guide wires these by hand.
- Reorder-list package: Flutter's built-in `ReorderableListView` covers reordering.
- YouTube Data API client: duration is optional in the spec, and oEmbed has no duration. The mockup shows a duration badge, so it becomes optional and hidden when unknown.
- Mocking packages (`mocktail`, `mockito`): tests use small hand-written fakes that implement the repository interfaces and use cases, as the arch guide describes (section 9). Fakes live under `test/fakes/`.
- Any stream-extraction package: violates YouTube's ToS (spec, section 3).

## Notes

- Android needs an intent filter for `text/plain` on the share activity. This is manifest config, not a package.
- `youtube_player_iframe` and `receive_sharing_intent` rely on platform plugins, so their Android minSdk and Gradle settings are checked after `flutter create`.
