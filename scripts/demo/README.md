# Demo video scripts

Drive YT Playlist and the YouTube app on a real Android phone over adb, record each step, and join the
takes into a captioned `docs/demo.mp4`. The scripts find buttons by their on-screen text. Only the
Share icon in YouTube is tapped by coordinates.

The flow recorded: open a video in YouTube and tap Share, pick the app in Android's share sheet, create
a folder and save the video, then play it from the folder.

## What you need

- Python 3 (no packages to install)
- `adb` and `scrcpy` (2.x), with the phone connected over USB and USB debugging on
- The official YouTube app on the phone, and an internet connection (the saved video plays through
  YouTube's player)
- `ffmpeg` built with the `drawtext` filter (captions). Some builds, such as Shotcut's, don't have it.
  Check with `ffmpeg -filters | grep drawtext`
- Keep the phone unlocked with the screen on while recording

## 1. Build a separate demo app

The script reinstalls the demo app to start from an empty library, so it must not be your real app.
Make two temporary edits (don't commit them):

- In `android/app/build.gradle.kts`, add to `buildTypes`:

  ```kotlin
  debug {
      applicationIdSuffix = ".demo"
  }
  ```

- In `android/app/src/main/AndroidManifest.xml`, change `android:label="YT Playlist"` to
  `android:label="YT Playlist Demo"`, so the demo is told apart from the real app in the share sheet.

Then build it, and undo the two edits with `git checkout android`:

```bash
flutter build apk --debug
```

The demo app is `com.example.youtube_saver.demo`. It installs next to the real app and doesn't touch its
library.

## 2. Record

From this folder. On Windows, set the full paths if the tools aren't on PATH:

```bash
export ADB="C:\Users\<you>\AppData\Local\Android\Sdk\platform-tools\adb.exe"
export SCRCPY="C:\path\to\scrcpy-win64-v2.5\scrcpy.exe"

python record_demo.py all        # reinstall the demo app, then record takes 1-4
```

Takes are saved in `out/take1.mkv` ... `out/take4.mkv`. Each take starts where the previous one ended
(take 2 continues from YouTube's share sheet, take 3 from the app's "Save to..." screen), so after a
failed take run `python record_demo.py all` again.

| Command | What it does |
|---|---|
| `python record_demo.py reset` | Uninstall and reinstall the demo app (empty library) and open it |
| `python record_demo.py N` | Record take N (1-4) |
| `python record_demo.py N norec` | Run take N without recording, to rehearse |
| `python record_demo.py all` | `reset`, then every take in order |

If a step can't find a button, the script saves `out/fail_takeN.png`, prints everything on screen and
exits.

## 3. Make the video

```bash
export FFMPEG="C:\path\to\ffmpeg.exe"
python make_video.py             # writes ../../docs/demo.mp4
python make_video.py my.mp4      # or choose the output file
```

This trims each take, speeds it up 1.25x, adds a caption (edit `CAPTIONS` in `make_video.py`) and
compresses to a small MP4.

**Check for private details before you publish.** Android's share sheet lists the phone owner's recent
contacts, so `make_video.py` blurs that band in take 2 (`BLUR`). If you record on another phone, look at
the result and adjust the band. The video is opened from its link rather than through YouTube search,
because search shows personal suggestions.

## Settings

| Env var | Default | Purpose |
|---|---|---|
| `ADB` | `adb` | Path to adb |
| `SCRCPY` | `scrcpy` | Path to scrcpy |
| `FFMPEG` | `ffmpeg` | Path to ffmpeg |
| `DEMO_PKG` | `com.example.youtube_saver.demo` | App id of the demo build |
| `DEMO_APK` | `build/app/outputs/flutter-apk/app-debug.apk` | APK reinstalled by `reset` |
| `DEMO_OUT` | `scripts/demo/out` | Where takes are saved |
| `CAPTION_FONT` | `C:/Windows/Fonts/arialbd.ttf` | Caption font (.ttf) |

## Notes

- `adb shell screenrecord` crashes on some phones, so recording uses `scrcpy --record`.
- `adb shell pm clear` is blocked on some phones, so `reset` reinstalls the app instead.
- Android's share sheet shows only a few apps per page and scrolls sideways. `take2` swipes until it
  finds "YT Playlist Demo", and taps that exact label so it never picks the real app.
- The share icon position (`SHARE_ICON` in `record_demo.py`) is for a 1080x2412 phone. Change it for other
  screens.
- To change the flow, edit the `take1` ... `take4` functions in `record_demo.py`. Helpers such as
  `tap("Create", exact=True)`, `fill(0, "text")` and `back()` are in `adb_driver.py`.
