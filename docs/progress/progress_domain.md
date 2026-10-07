# Progress: domain

Use cases only (`lib/domain/use_cases/`). Depends on the data repository interfaces.

| Use case | Kind | Status |
|---|---|---|
| `save_shared_video` (parse URL, fetch oEmbed, save to chosen folder) | Business | Not started |
| `create_folder` (validate name, unique among siblings) | Business | Not started |
| `rename_folder` / `rename_video` | Business | Not started |
| `move_folder` (reject move into itself or a descendant) / `move_video` | Business | Not started |
| `delete_folder` / `delete_video` | Business | Not started |
| `reorder_items` | Business | Not started |
| `list_folder_contents` (folders + videos, live) | UI | Not started |
| `get_folder_path` (breadcrumb) | UI | Not started |
| `get_play_queue` (direct videos of a folder, ordered) | UI | Not started |

## Notes
- Business and UI use cases are split into `business/` and `ui/` folders, as in guide section 6.3.1.
- A shared URL parser (extract the 11-character id from `youtu.be` and `youtube.com` links) is a pure helper next to `save_shared_video`.
