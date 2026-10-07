# YT Playlist: building the APK

<img src="app_icon.png" width="96" alt="YT Playlist icon">

- **Name on the phone:** YT Playlist (`android:label` in `AndroidManifest.xml`).
- **Version:** `1.0.0+1` in `pubspec.yaml`. `1.0.0` is the version name people see. The number after `+` is the Android version code and must go up by one for every APK you want to install over the previous one (`1.0.0+2`, `1.0.1+3`, ...).
- **Package ids:** the Dart package is still `youtube_saver` and the Android application id is `com.example.youtube_saver`. Neither shows in the app.

## Build

```
flutter build apk --release
```

The file is `build/app/outputs/flutter-apk/app-release.apk`. For a smaller file per phone type, use `flutter build apk --release --split-per-abi` and install the `arm64-v8a` one on a modern phone.

Install with `adb install -r build/app/outputs/flutter-apk/app-release.apk`, or copy the file to the phone and open it (allow "install unknown apps" for the file manager).

## Signing
The release build is signed with the **debug key** of the machine that builds it (`android/app/build.gradle.kts`). That is fine for your own use. An APK built on a different machine, or after that key is regenerated, cannot be installed over the old one: uninstall first (the saved library is lost). To keep updating in place, create a keystore and point `signingConfigs` at it.

## Icon
`tool/generate_icon.py` draws the icon (a white folder with a red play triangle on a near-black tile) and writes every Android resource: adaptive icon layers, the Android 13 themed icon and the legacy icons. Run `python tool/generate_icon.py` from the project root after changing it (needs `pip install pillow`).
