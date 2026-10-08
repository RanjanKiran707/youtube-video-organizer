# YT Playlist (youtube_saver)

<img src="docs/app_icon.png" width="96" alt="YT Playlist icon">

An Android app for saving YouTube videos into your own folders. Share a video from the YouTube app, pick a folder, and play it later inside the app. The library is stored on the device, with no account, sync or backend.

## Demo

https://github.com/user-attachments/assets/07e2abb0-2934-483a-b241-6c7d1ac70970

Open a video in YouTube, share it to YT Playlist, create a folder and save it there, then play it from the folder. The scripts that record it are in [scripts/demo](scripts/demo/README.md).

## Features

- **Share to save**: in the YouTube app, tap a video, press Share and choose YT Playlist. A folder picker opens, and the video is saved only after you choose a folder.
- **Nested folders**: create folders to any depth. A folder can hold videos, other folders, or both. Create a folder from the picker while saving.
- **In-app playback**: videos play inside the app with the official YouTube IFrame player, so you are never sent to the YouTube app.
- **Auto-advance**: when a video ends, the next video in the same folder starts. Only the videos directly in that folder are queued, not subfolders.
- **Embed fallback**: a video that can't be embedded (embedding disabled, private or deleted) shows a clear error and an "Open in YouTube" option. Auto-advance skips it.
- **Title and thumbnail** are fetched through YouTube's oEmbed endpoint, so no API key is needed.

## Tech stack

- Flutter (Android only)
- [`receive_sharing_intent`](https://pub.dev/packages/receive_sharing_intent) to receive the YouTube share
- [`youtube_player_iframe`](https://pub.dev/packages/youtube_player_iframe) for playback
- [`drift`](https://pub.dev/packages/drift) and `drift_flutter` for local SQLite storage
- `http`, `url_launcher`, `uuid`, `cached_network_image`

The code follows a layered structure: `lib/core`, `lib/data`, `lib/domain` (use cases) and `lib/features`. State uses `ValueNotifier` and dependencies are wired by hand, with no state-management or DI packages.

## Getting started

Requirements: the Flutter SDK and an Android device or emulator.

```bash
git clone https://github.com/RanjanKiran707/youtube_saver.git
cd youtube_saver
flutter pub get
dart run build_runner build   # generates the drift database code
flutter run
```

To build an APK, see [docs/release.md](docs/release.md).

## Known limits

- Android only. iOS is out of scope.
- No true background playback or screen-off audio, because the official embedded player doesn't support it.
- Ads still play where YouTube serves them.
- Data lives only on the device. Uninstalling the app removes the library.

## Docs

- [Product spec](project_spec/product_spec.md)
- [Data model](docs/data_model.md)
- [Dependencies](docs/dependencies.md)
- [Release guide](docs/release.md)
