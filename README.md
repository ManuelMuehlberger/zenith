# workout_tracker

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Git Hooks

This repo includes versioned git hooks in `.githooks/`.

Run this once after cloning:

```sh
git config core.hooksPath .githooks
```

The hooks only operate on changed `.dart` files, and they block commit/push if
that changed set does not pass a clean `flutter analyze`.

If you want to run the same UI policy against the full app instead of just the
delta, use:

```sh
scripts/check_changed_dart_policy.sh --all
```

The hook chain now does several things on changed Dart files:

- Runs formatting and requires a clean `flutter analyze` on changed Dart files.
- Runs a UI policy scan that enforces theme-only styling.
- Runs a maintainability gate for changed production Dart files.
- Runs a changed-file coverage gate for non-frontend Dart files.

Blocking policy checks:

- `withOpacity(...)` usage in `lib/`.
- Raw `Colors.*` or `CupertinoColors.*` usage outside `lib/theme/`.
- Hardcoded color constructors outside `lib/theme/`.
- `TextStyle(...)`, `TextTheme(...)`, `ColorScheme(...)`, or `ThemeData(...)` definitions outside `lib/theme/`.
- Newly added direct `AppThemeColors.*` or `AppTextStyles.*` usage outside `lib/theme/` on changed-file scans (`--all` blocks any remaining usage).

Maintainability gate:

- `scripts/check_changed_dart_maintainability.py` enforces architecture boundaries, a changed-function complexity budget, changed-file test adjacency, and explicit annotation for new public top-level API surface.
- Architecture checks block non-UI layers from importing screens/widgets, block UI from importing DAOs or low-level database services directly, and block insights code from reaching into persistence internals.
- Complexity checks apply to changed functions and block functions above `80` lines, above `10` decision points, or above nesting depth `5`.
- Test adjacency checks require non-trivial production changes to also change a matching `test/<path>*_test.dart` file unless the file explicitly opts out.
- Public API checks require explicit annotation for newly added public top-level `class`/`enum`/`mixin`/`extension`/`typedef`, `export`, and public top-level functions.
- Diff-only checks run on `--staged` and `--range`; `--all` runs only the architecture and complexity checks.

Allowed escape hatches for exceptional cases:

- `// policy: allow-boundary <reason>` to bypass an architecture rule in a file.
- `// policy: allow-complexity <reason>` to bypass the complexity budget in a file.
- `// policy: no-test-needed <reason>` to bypass changed-file test adjacency in a file.
- `// policy: allow-public-api <reason>` on or immediately above a new public top-level declaration or export.

Warning-only policy checks:

- Likely inline user-facing strings.

Coverage gate:

- `scripts/check_changed_dart_coverage.sh` is now a stable shell entrypoint that delegates to `scripts/check_changed_dart_coverage.py`.
- The gate combines two checks from one authoritative cached `flutter test --coverage` run: all Dart tests must pass, and changed non-frontend production files must meet the coverage threshold.
- The pre-push hook forces a fresh full-suite coverage run by setting `ZENITH_DISABLE_COVERAGE_CACHE=1`, so pushes validate against a new `flutter test --coverage` execution instead of a reused local cache.
- The script caches that full-suite test+coverage artifact under `.dart_tool/coverage_gate/` and reuses it when no `lib/**/*.dart`, `test/**/*.dart`, `pubspec.yaml`, `pubspec.lock`, or coverage-script inputs have changed.
- Set `ZENITH_DISABLE_COVERAGE_CACHE=1` to force a fresh coverage run.
- Set `ZENITH_COVERAGE_CACHE_DEBUG=1` to print cache fingerprint decisions.
- Frontend paths are excluded from enforcement: `lib/screens/`, `lib/widgets/`, `lib/theme/`, and `lib/main.dart`.
- Non-instrumentable files are also excluded from enforcement: `lib/models/typedefs.dart` and `lib/services/insights/insight_data_provider.dart`.
- The minimum per-file coverage defaults to `80%` and can be overridden with the `ZENITH_MIN_CHANGED_FILE_COVERAGE` environment variable.

Theme and token definitions now belong in `lib/theme/`. UI code should consume them through `context.appScheme`, `context.appText`, and `context.appColors`. Direct `AppThemeColors` and `AppTextStyles` references are compatibility aliases that should only shrink over time, not be added back into non-theme UI code.

## CI Toolchain Image

This repo supports a promoted CI toolchain image that preinstalls Java,
Flutter, and Android SDK components for faster self-hosted CI runs. The main
quality gate auto-detects that toolchain and skips setup steps when it is
already present, while still keeping fallback setup steps for compatibility.

See `docs/ci_toolchain_image.md` for the image lifecycle, promotion flow,
required secrets and variables, and the runner label configuration.
