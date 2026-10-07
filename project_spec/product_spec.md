## Youtube Playlist saver

### Requirements

1. **Share-to-app**: In the YouTube app, tap a video, press Share, and pick this app as the target. The app opens a folder picker where the user navigates the folder tree (and can create a folder) and selects where the video should be stored. The video is saved only after a folder is chosen.
2. **Folders**: The user can create folders. A folder can contain videos and/or other folders (nested, any depth).
3. **In-app playback**: The user can play a saved video inside this app, without being sent to the YouTube app.
4. **Auto-advance**: When a video in a folder finishes, the next video in that same folder starts playing automatically. Only the videos directly in the current folder are queued; subfolders are not included.

### Decisions

- **Platform**: Android only. iOS is out of scope for now.
- **Storage**: Local to the device only. No sync, no account, no backend.
- **Auto-advance scope**: The current folder's direct videos only.
- **Save flow**: The user picks the destination folder at share time. There is no Inbox.

### Feasibility assessment

| # | Requirement | Verdict | Notes |
|---|-------------|---------|-------|
| 1 | Share from YouTube app + pick folder | Feasible on Android | See below |
| 2 | Nested folders | Feasible | Simple tree data model |
| 3 | In-app playback | Feasible, with limits | Must use the official YouTube embed player |
| 4 | Auto-advance | Feasible | Player exposes an "ended" event |

**1. Share-to-app and folder picker**
- The YouTube share sheet sends the video URL as plain text (e.g. `https://youtu.be/<id>`). The app registers as a receiver of shared text and extracts the video ID.
- Android: register an `ACTION_SEND` / `text/plain` intent filter on an Activity. That Activity shows the folder picker UI, then saves the video. Works with native Android, React Native, or Tauri v2 mobile (the latter needs a small custom plugin/Kotlin code to receive the intent).
- A native or Tauri-mobile app fits this flow best, since the share opens a dedicated picker screen. An installed PWA with a Web Share Target can also open a page containing the picker, so both remain viable.
- A desktop-only app (like the sibling Clipper project) cannot receive shares from the YouTube mobile app.
- Title and thumbnail can be fetched without an API key via YouTube's oEmbed endpoint (`youtube.com/oembed?url=...&format=json`). The YouTube Data API v3 is optional, for duration and richer metadata.
- iOS (Share Extension) is out of scope.

**2. Folders**
- Data model: a tree of nodes, each with `id`, `parentId`, `type` (`folder` or `video`), `name`, `position`, and for videos `videoId`, `title`, `thumbnail`.
- Needs: create, rename, delete, move between folders, and reorder.
- The share-time picker reuses the same folder browser as the main app, with a "create folder" action and a "Save here" button.
- Local storage: SQLite (native/Tauri) or IndexedDB (web). A single tree table is enough.

**3. In-app playback**
- Use the YouTube IFrame Player API (a WebView on Android). This is the officially supported way and is within the Terms of Service.
- Limits:
  - Some videos have embedding disabled by the owner (player errors 101/150). The app must detect this and offer "Open in YouTube" as a fallback.
  - Ads still play where YouTube serves them. YouTube Premium benefits do not apply inside an embed.
  - Background playback and screen-off audio are not officially supported in embeds. On Android a WebView may pause when the app is backgrounded.
  - Downloading or extracting the video stream to play it natively violates YouTube's ToS. Do not do this.
  - Private or deleted videos will fail. Show a clear error state.

**4. Auto-advance**
- The IFrame Player API fires `onStateChange` with `YT.PlayerState.ENDED`. On that event, call `loadVideoById(nextId)` for the next video in the current folder's order.
- Videos that fail to embed are skipped automatically.

### Overall verdict

The whole feature set is feasible on Android. The main risks are:
1. **Embed restrictions**: a small share of videos won't play in-app and need a fallback.
2. **No true background playback** using the official player.
3. **Share-intent plumbing**: if Tauri mobile is chosen, receiving the share intent needs custom Kotlin code.

### Still open

- What happens when the last video in a folder ends: stop, or loop back to the first?
- Tech stack: native Android, Tauri v2 mobile (reusing the Clipper stack), or a PWA?
