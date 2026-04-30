# Logging Guidelines

- Use `package:logging` with `Logger('TypeName')` and let [lib/utils/app_logger.dart](/Users/manu/Documents/Projects/zenith/lib/utils/app_logger.dart) handle the sink.
- Log lifecycle transitions, user-triggered state changes, persistence boundaries, and failures.
- Do not add logs in `build()` methods or other hot render paths unless diagnosing a temporary issue.
- Use `info` for important app-flow events, `fine`/`finer` for optional diagnostics, `warning` for unexpected recoverable states, and `severe` for failures with `error` and `stackTrace`.
- Prefer structured, compact messages with identifiers such as session id, exercise id, tab index, or counts.
- UI-only widgets should usually stay quiet unless they coordinate navigation, async work, or destructive actions.
