# Code Review

Date: 2026-04-30

## Summary

The app is in a workable state and the database layer is stronger than the rest of the codebase. The SQLite and DAO structure is reasonably sound, migrations exist, and the project has a better-than-average automated test suite for a Flutter app of this size.

The main design issue is the layer above persistence. State is managed through singleton services, manual refresh calls, and direct widget coordination instead of a consistent observable state model. That makes the app harder to reason about, easier to break with incidental changes, and more expensive to scale.

The codebase looks like a successful prototype that has accumulated production features faster than its architecture has been tightened. That is recoverable. The main concerns are fixable without a rewrite.

## General Design Assessment

### What is sound

- The DAO layer is a good foundation. The generic base DAO and per-table DAOs are a reasonable separation point.
- SQLite is an appropriate persistence choice for this app.
- The test suite is substantial, especially around services and models.
- The app clearly has a coherent product scope: workout templates, active sessions, history, calendar, insights, and profile data all fit together.

### What is not sound enough

- Global singleton services are used as data access, in-memory cache, and application state holders at the same time.
- Screen-to-screen refresh behavior is coordinated through imperative hooks rather than state observation.
- Several screens and widgets have become oversized and now combine UI rendering, interaction handling, domain logic, and helper utilities in one file.
- Models are inconsistent in mutability and serialization style.
- There is at least one stale persistence path that can mislead future changes.

## High-Priority Issues

### 1. Conflicting persistence paths

Files:
- [lib/services/database_service.dart](/Users/manu/Documents/Projects/zenith/lib/services/database_service.dart)
- [lib/services/insights_service.dart](/Users/manu/Documents/Projects/zenith/lib/services/insights_service.dart)
- [lib/services/workout_service.dart](/Users/manu/Documents/Projects/zenith/lib/services/workout_service.dart)

What is bad:

`DatabaseService` still writes workouts into `SharedPreferences`, while the rest of the app reads workout data from SQLite through the service and DAO stack.

Why this matters:

- It creates a split-brain persistence design.
- Future contributors can write to the wrong storage path and assume the app state is persisted correctly.
- Dead or partially-dead data paths increase maintenance risk because they appear valid but are not part of the real data flow.

Suggestion:

- Remove the `SharedPreferences` workout write/delete path entirely if it is no longer used.
- Route all workout reads and writes through the SQLite-backed service/DAO layer.
- If `DatabaseService` only remains as legacy glue, delete it and update callers to use the real source of truth directly.

### 2. State management is ad hoc and tightly coupled

Files:
- [lib/main.dart](/Users/manu/Documents/Projects/zenith/lib/main.dart)
- [lib/utils/navigation_helper.dart](/Users/manu/Documents/Projects/zenith/lib/utils/navigation_helper.dart)
- [lib/services/user_service.dart](/Users/manu/Documents/Projects/zenith/lib/services/user_service.dart)
- [lib/services/workout_service.dart](/Users/manu/Documents/Projects/zenith/lib/services/workout_service.dart)

What is bad:

The app uses singleton services and manual `setState`, plus imperative refresh triggers such as a `GlobalKey<HomeScreenState>` and static callback registration in `NavigationHelper`.

Why this matters:

- Widgets depend on implementation details of other widgets.
- Refresh flows become implicit and fragile.
- It is difficult to know what should react to changes and when.
- This approach scales poorly as more screens and background updates are added.

Suggestion:

- Standardize on an observable state mechanism.
- A low-disruption improvement would be to make the core singleton services extend `ChangeNotifier` and have widgets observe them consistently.
- A larger but cleaner improvement would be to adopt a state-management package such as Riverpod or Provider.
- Remove `GlobalKey`-driven refreshes and static navigation callbacks once service-level notifications exist.

### 3. Model design is inconsistent and risky

Files:
- [lib/models/workout.dart](/Users/manu/Documents/Projects/zenith/lib/models/workout.dart)
- [lib/models/exercise.dart](/Users/manu/Documents/Projects/zenith/lib/models/exercise.dart)
- [lib/models/user_data.dart](/Users/manu/Documents/Projects/zenith/lib/models/user_data.dart)

What is bad:

Some models are immutable, some are mutable, and some mix mutability with `copyWith`. Serialization is hand-written and permissive, especially in `Exercise.fromMap`.

Why this matters:

- Mutable shared models are hard to reason about when services cache instances.
- Mixing mutation and `copyWith` undermines ownership assumptions.
- Loose `Map<String, dynamic>` parsing hides schema problems and encourages silent compatibility branches instead of explicit migrations.

Suggestion:

- Make domain models immutable.
- Adopt `freezed` and `json_serializable`, or at minimum convert fields to `final` and centralize map parsing.
- Remove sentinel-based `copyWith` patterns where generated immutable models would be clearer and safer.

### 4. Several files are too large and carry too many responsibilities

Files:
- [lib/screens/home_screen.dart](/Users/manu/Documents/Projects/zenith/lib/screens/home_screen.dart)
- [lib/screens/insights_screen.dart](/Users/manu/Documents/Projects/zenith/lib/screens/insights_screen.dart)
- [lib/screens/create_workout_screen.dart](/Users/manu/Documents/Projects/zenith/lib/screens/create_workout_screen.dart)
- [lib/screens/active_workout_screen.dart](/Users/manu/Documents/Projects/zenith/lib/screens/active_workout_screen.dart)
- [lib/widgets/edit_exercise_card.dart](/Users/manu/Documents/Projects/zenith/lib/widgets/edit_exercise_card.dart)
- [lib/services/insights_service.dart](/Users/manu/Documents/Projects/zenith/lib/services/insights_service.dart)

What is bad:

Core screens and at least one widget are effectively god-classes. They combine large build trees with custom animation logic, data orchestration, helper functions, painters, state machines, and domain logic.

Why this matters:

- Large files increase regression risk during small changes.
- Reuse becomes difficult because logic is embedded in monolithic screens.
- Tests become more expensive to write and maintain.
- Developers are more likely to apply local patches instead of improving design.

Suggestion:

- Extract view sections into smaller widgets.
- Move orchestration and data transformation into controller/service classes or dedicated view models.
- Keep screens focused on composition and navigation.
- Treat any file approaching or exceeding roughly 500 lines as a candidate for structural extraction.

### 5. Rebuild strategy is inefficient in hot paths

Files:
- [lib/screens/active_workout_screen.dart](/Users/manu/Documents/Projects/zenith/lib/screens/active_workout_screen.dart)
- [lib/services/workout_service.dart](/Users/manu/Documents/Projects/zenith/lib/services/workout_service.dart)

What is bad:

The active workout screen rebuilds every second via `Timer.periodic` and `setState`, and workout loading uses N+1 database access patterns.

Why this matters:

- Rebuilding large trees for a timer label wastes work and battery.
- N+1 queries become noticeable as the amount of stored workout data grows.
- Performance issues in workout tracking apps are especially visible during active use.

Suggestion:

- Isolate the timer display into its own small widget or notifier-backed listener.
- Batch workout loading with joins or grouped queries.
- Avoid full-screen rebuilds when only one derived value changes.

### 6. Startup does too much work before `runApp`

Files:
- [lib/main.dart](/Users/manu/Documents/Projects/zenith/lib/main.dart)

What is bad:

Multiple services are initialized serially before the app UI is shown.

Why this matters:

- Cold-start latency becomes more visible.
- Failures during startup are harder to surface gracefully.
- The app cannot render a responsive shell while background initialization completes.

Suggestion:

- Keep only essential platform/bootstrap work before `runApp`.
- Move data loading behind an app bootstrap screen, app wrapper, or asynchronous initialization flow.
- Parallelize non-dependent startup work where possible.

### 7. Logging, diagnostics, and code hygiene are inconsistent

Files:
- [lib/widgets/exercise_list_widget.dart](/Users/manu/Documents/Projects/zenith/lib/widgets/exercise_list_widget.dart)
- [lib/widgets/workout_chart.dart](/Users/manu/Documents/Projects/zenith/lib/widgets/workout_chart.dart)
- [lib/main.dart](/Users/manu/Documents/Projects/zenith/lib/main.dart)
- [analysis_options.yaml](/Users/manu/Documents/Projects/zenith/analysis_options.yaml)

What is bad:

The app contains many `debugPrint` calls despite also having a logger setup, and linting remains close to the default Flutter baseline.

Why this matters:

- Logging strategy becomes inconsistent.
- Debug-only instrumentation leaks into normal code paths.
- Weak lints allow preventable issues to accumulate.

Suggestion:

- Choose one logging approach and standardize it.
- Remove incidental `debugPrint` usage.
- Increase lint strictness, especially around `const`, async handling, null safety, and build-context misuse.

### 8. Null-safety discipline is weaker than it should be

Files:
- [lib/services/workout_session_service.dart](/Users/manu/Documents/Projects/zenith/lib/services/workout_session_service.dart)
- [lib/screens/create_workout_screen.dart](/Users/manu/Documents/Projects/zenith/lib/screens/create_workout_screen.dart)

What is bad:

The code relies heavily on `!` in several important flows.

Why this matters:

- It reduces the value of Dart null safety.
- Runtime crashes move from compile time to production execution paths.
- These are the kinds of issues that appear only under edge cases or timing-dependent flows.

Suggestion:

- Replace bang operators with proper local guards and narrowed control flow.
- Refactor methods so nullable state is resolved once, early, and explicitly.
- Add lints and tests around edge-case session transitions.

## Medium-Priority Improvements

### Theme and design system are not centralized enough

Files:
- [lib/main.dart](/Users/manu/Documents/Projects/zenith/lib/main.dart)
- [lib/constants/app_constants.dart](/Users/manu/Documents/Projects/zenith/lib/constants/app_constants.dart)

Issue:

Theme configuration exists, but many screens still hardcode colors, spacing decisions, and text styles instead of leaning on a shared theme system.

Suggestion:

- Move more visual decisions into `ThemeData`, theme extensions, or dedicated design tokens.
- Reduce direct `Colors.black` and ad hoc style construction in screens.

### Hardcoded strings and magic numbers

Files:
- [lib/screens/home_screen.dart](/Users/manu/Documents/Projects/zenith/lib/screens/home_screen.dart)
- [lib/screens/active_workout_screen.dart](/Users/manu/Documents/Projects/zenith/lib/screens/active_workout_screen.dart)

Issue:

Thresholds, delays, and UI copy are embedded directly in widgets.

Suggestion:

- Extract repeat values into constants.
- Prepare for localization by reducing inline user-facing strings.

### Deprecated color API usage

Files:
- [lib/screens/home_screen.dart](/Users/manu/Documents/Projects/zenith/lib/screens/home_screen.dart)
- [lib/widgets/timeline/timeline_row.dart](/Users/manu/Documents/Projects/zenith/lib/widgets/timeline/timeline_row.dart)
- [lib/widgets/edit_exercise_card.dart](/Users/manu/Documents/Projects/zenith/lib/widgets/edit_exercise_card.dart)

Issue:

The project still uses `withOpacity` in many places.

Suggestion:

- Replace it with `withValues(alpha: ...)` throughout the codebase.

## Low-Hanging Fruit

These are changes that should be relatively easy and offer immediate value.

1. Remove the stale `SharedPreferences` workout persistence path.
2. Delete or standardize stray `debugPrint` calls.
3. Tighten lint rules in [analysis_options.yaml](/Users/manu/Documents/Projects/zenith/analysis_options.yaml).
4. Replace deprecated `withOpacity` usage.
5. Remove no-op or dead code paths such as unused save methods and placeholder branches.
6. Extract timer-specific UI updates away from full-screen rebuilds.
7. Move repeated thresholds and timings into shared constants.
8. Replace the most obvious `!` chains with guarded control flow.
9. Split one large screen, starting with the home screen, into composable sections.
10. Standardize service notifications instead of manual refresh wiring.

## Suggested Refactoring Order

### Phase 1: Safety and cleanup

- Remove dead persistence paths.
- Increase lint strictness.
- Remove stray debug logging.
- Replace deprecated API calls.
- Clean up obvious null-safety hotspots.

### Phase 2: State flow stabilization

- Introduce consistent observable state for core services.
- Eliminate `GlobalKey`-driven screen refresh.
- Remove static callback registration where normal state updates should be used.

### Phase 3: Model and service hardening

- Make models immutable.
- Simplify serialization.
- Reduce in-memory cache ambiguity.
- Clarify ownership boundaries between DAO, service, and UI state.

### Phase 4: Structural extraction

- Break up oversized screens and widgets.
- Move non-UI logic out of widget files.
- Keep screens as composition roots rather than logic containers.

## Final Assessment

The app design is not fundamentally broken, but it is not cleanly scaled. The persistence layer and tests are solid enough that the project has a good base. The main problems are architectural drift, overgrown screen files, and implicit state coordination.

This is not a rewrite situation. It is a prioritization situation. If the team addresses the state flow, model immutability, and dead persistence code first, the rest of the cleanup becomes much cheaper and safer.