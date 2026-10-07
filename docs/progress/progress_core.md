# Progress: core

Shared pieces used by the whole app (`lib/core/`). Source: `project_spec/flutter_arch_general.md` sections 3 and 4.

| Item | File | Status |
|---|---|---|
| Failure (Validation, Storage, Unexpected) | `errors/failure.dart` | Done |
| Result (`Ok`, `Err`, `fold`, `map`, `flatMap`) | `errors/result.dart` | Done |
| ViewState (+ `when`, `isLoading`) | `utils/view_state.dart` | Done |
| ObxValue, ObxMulti | `widgets/obx_value.dart` | Done |
| AppDependencies (empty, wired in `main()`) | `di/app_dependencies.dart` | Done, grows with data and domain |

## Notes
- `map` and `flatMap` are added to `Result` because the guide's `ListStudentsUsecase` example uses them but its `Result` listing omits them.
- `main.dart` now calls `AppDependencies.init()` before `runApp`. The default counter app is still there until the first feature replaces it.

## Next
- Add a failure type only when a caller handles it differently (for example `NotFoundFailure`, `ConflictFailure` for duplicate folder names).
- Add the app theme (colors from the mockup) when the first feature view is built.
