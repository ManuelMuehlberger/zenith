# Copilot Instructions

## Build, test, and lint commands

```sh
flutter pub get

# Full-project checks
flutter analyze
flutter test
flutter build apk            # or: flutter build ios / flutter build web

# Run a single test file
flutter test test/services/workout_session_service_test.dart

# Run a single named test
flutter test --plain-name "shows retry UI when bootstrapping fails and retries successfully" test/screens/app_wrapper_test.dart

# Changed-file lint/policy checks used by the repo hooks
scripts/lint_changed_dart.sh --staged
scripts/lint_changed_dart.sh --range <from-ref> <to-ref>
scripts/check_changed_dart_policy.sh --staged
scripts/check_changed_dart_policy.sh --range <from-ref> <to-ref>
scripts/check_changed_dart_policy.sh --all

# Enable the versioned git hooks after clone
git config core.hooksPath .githooks
```

Use the changed-file scripts for incremental work. `flutter analyze` is still useful, but the repo intentionally keeps the hook checks scoped to changed Dart files because the wider codebase has existing analyzer findings.

## High-level architecture

- `lib/main.dart` creates the app shell with `AppTheme.dark` and routes through `AppWrapper`.
- `AppWrapper` decides whether to show onboarding or the main app. It checks onboarding via `UserService`, then bootstraps exercises, workouts, user data, notifications, and any active session through `AppStartupService`.
- The main shell is `MainScreen`, a 3-tab app (`HomeScreen`, `WorkoutBuilderScreen`, `InsightsScreen`) driven by `AppNavigationService`.
- Primary persistence is SQLite. `DatabaseHelper` owns schema creation/migrations and seeds the exercise catalog from `assets/gym_exercises_complete.toml`. Table-level access lives in `lib/services/dao/`, and higher-level orchestration/caching lives in singleton-style services such as `WorkoutService`, `WorkoutTemplateService`, `ExerciseService`, and `UserService`.
- Workout planning and workout execution are separate flows. The builder path uses `WorkoutTemplateService`, `WorkoutTemplate`, and `WorkoutFolder`. The active-session path uses `WorkoutSessionService`, which clones template exercises/sets into session-scoped `Workout` records, keeps the live notification service in sync, and writes completed sessions back into history consumed by `WorkoutService`.
- Home/timeline rendering is assembled from services instead of built directly from raw queries. `WorkoutTimelineGroupingService` splits completed workouts into recent/archive buckets, and `HomeTimelineAssembler` maps those buckets into `TimelineListItem` structures plus month metrics.
- Insights screens delegate aggregation to `InsightsService` and the provider classes under `lib/services/insights/`. Those results are cached through `InsightsCacheStore` rather than recalculated in widgets.

## Key conventions

- Treat the SQLite + DAO + service stack as the main source of truth. `DatabaseService` is SharedPreferences-backed legacy/settings glue and is not the primary workout persistence path.
- Follow the existing singleton-and-injection testing pattern. Many services expose `*.instance`, `withDependencies(...)`, `setDependenciesForTesting(...)`, or `@visibleForTesting` setters so tests can swap DAOs and notification services without rewriting app wiring.
- For non-UI changes, add or update the matching unit tests when practical. The repo already has broad coverage in `test/services/`, `test/models/`, and `test/services/dao/`; follow those patterns before reaching for new widget-level tests.
- Keep visual tokens in `lib/theme/`. Outside that directory, consume styling through `context.appScheme`, `context.appText`, and `context.appColors` from `lib/theme/app_theme.dart`, or existing `AppTheme`/`AppConstants` compatibility aliases only when necessary.
- Respect the UI policy scripts from `README.md` and `scripts/check_changed_dart_policy.sh`: new raw `Colors.*` / `CupertinoColors.*`, hardcoded `Color(...)`, new `TextStyle(...)` / `ThemeData(...)` / `ColorScheme(...)`, and `withOpacity(...)` usage are not allowed outside `lib/theme/`. Use `withValues(alpha: ...)` instead.
- Use `package:logging` and `Logger('TypeName')`, with output routed through `lib/utils/app_logger.dart`. Prefer structured lifecycle/state/persistence logs and avoid adding logs in hot widget build paths.
- If you change exercise data or schema, update the seed asset, the schema/migration code in `DatabaseHelper`, and the model/DAO parsing together. `Exercise.fromMap()`/`toMap()` intentionally bridge mixed snake_case and camelCase payloads for compatibility.
