# Progress: features

One View + ViewModel per screen (`lib/features/`). Designs: `project_spec/mockup.html`.

| Feature | Mockup screen | Status |
|---|---|---|
| `library` (root and folder view, play all, item menus, empty state) | 1, 4, 7 | Not started |
| `folder_picker` (share target sheet, navigate, "Save to X") | 2 | Not started |
| `new_folder` dialog | 3 | Not started |
| `player` (embed, up next, auto-advance, can't-embed fallback, queue end) | 5, 6, end note | Not started |

## Notes
- The folder browser is shared between `library` and `folder_picker`.
- The blocking rule (guide 7.1) applies to every one-off action.
- Open question from the spec: behaviour at the end of a folder. The mockup assumes playback stops.
- Android share intent filter (`text/plain`) is added with `folder_picker`.
