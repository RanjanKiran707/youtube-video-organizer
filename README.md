# 📺 YouTube Video Organizer (YT Playlist)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Database](https://img.shields.io/badge/SQLite-Drift-blue?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Tests](https://img.shields.io/badge/Tests-93%20Passing-brightgreen?style=for-the-badge&logo=checkmarx&logoColor=white)](test/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2F%20Layered-blue?style=for-the-badge)](project_spec/flutter_arch_general.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

An Android application that allows you to organize YouTube videos into custom nested folders directly via the native YouTube share sheet. Save videos on the fly, play them back in-app with auto-advance, and keep your video library completely offline on your device with zero cloud dependency.

> **🚀 [Try the Live Web Demo](https://yt-video-organizer.web.app)**  
> **📦 [Download Android Release APK (v1.0.0)](https://github.com/RanjanKiran707/youtube-video-organizer/releases/tag/v1.0.0)**

---

<p align="center">
  <img src="docs/app_icon.png" width="96" alt="YT Playlist icon">
</p>

## 🎬 Demo

https://github.com/user-attachments/assets/07e2abb0-2934-483a-b241-6c7d1ac70970

*Share a video from YouTube, pick a folder, and play it directly in the app. Full-quality video demo in [docs/demo.mp4](docs/demo.mp4).*

---

## ✨ Features

- **Share to Save:** Tap **Share** on any video in the YouTube app and choose **YT Playlist**. A clean folder picker opens, allowing you to select an existing folder or create a new one instantly.
- **Nested Folder Hierarchy:** Create folders to any depth. A folder can hold videos, subfolders, or both.
- **In-App Distraction-Free Playback:** Plays videos smoothly using the official YouTube IFrame player without redirecting away from the app.
- **Auto-Advance Playlists:** When a video finishes playing, the next video in that folder automatically starts.
- **Graceful Embed Fallback:** Videos that disallow embedding (e.g. private, restricted, or deleted) show a clear error with a direct "Open in YouTube" button.
- **Zero API Keys:** Titles and thumbnails are resolved seamlessly via YouTube's public oEmbed endpoint.

---

## 🏛️ Engineering & Architecture (93 Automated Tests)

- **93 Automated Tests:**
  - **20 Data Layer Tests:** Validates Drift database migrations, folder trees, and local persistence.
  - **39 Domain Business Tests:** Use case tests for playlist navigation, auto-advance queueing, and folder creation.
  - **34 Feature & UI Tests:** View models, folder picker dialogs, and video player state machines.
- **Minimalist State Management:** Uses Dart's native `ValueNotifier` and explicit manual dependency injection—deliberately avoiding heavy third-party framework overhead.
- **Layered Clean Architecture:** Strict separation between `lib/core`, `lib/data`, `lib/domain` (use cases), and `lib/features`.

---

## 🛠️ Tech Stack

- **Flutter & Dart**
- [`receive_sharing_intent`](https://pub.dev/packages/receive_sharing_intent) (Native Android share sheet intent integration)
- [`youtube_player_iframe`](https://pub.dev/packages/youtube_player_iframe) (Video playback)
- [`drift`](https://pub.dev/packages/drift) & `drift_flutter` (Local SQLite database)
- `http`, `url_launcher`, `uuid`, `cached_network_image`

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.x or later)
- Android SDK or connected device / emulator

### Setup & Run
```bash
# Clone the repository
git clone https://github.com/RanjanKiran707/youtube-video-organizer.git
cd youtube-video-organizer

# Install dependencies
flutter pub get

# Generate Drift SQLite database code
dart run build_runner build

# Run application
flutter run

# Run all 93 automated tests
flutter test
```

To build a release APK yourself, see the [Release Guide](docs/release.md).

---

## 📚 Technical Documentation

- [Product Specifications](project_spec/product_spec.md)
- [Architecture Guide](project_spec/flutter_arch_general.md)
- [Data Model & Schema](docs/data_model.md)
- [Dependency Analysis](docs/dependencies.md)
- [Release Guide](docs/release.md)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
