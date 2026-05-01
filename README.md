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

The hooks lint only changed `.dart` files so they stay usable while the wider
codebase still has unrelated analyzer findings.

If you want to run the same UI policy against the full app instead of just the
delta, use:

```sh
scripts/check_changed_dart_policy.sh --all
```

The hook chain now does two things on changed Dart files:

- Runs formatting and analyzer checks.
- Runs a UI policy scan that enforces theme-only styling.

Blocking policy checks:

- `withOpacity(...)` usage in `lib/`.
- Raw `Colors.*` or `CupertinoColors.*` usage outside `lib/theme/`.
- Hardcoded color constructors outside `lib/theme/`.
- `TextStyle(...)`, `TextTheme(...)`, `ColorScheme(...)`, or `ThemeData(...)` definitions outside `lib/theme/`.
- Newly added direct `AppThemeColors.*` or `AppTextStyles.*` usage outside `lib/theme/` on changed-file scans (`--all` blocks any remaining usage).

Warning-only policy checks:

- Likely inline user-facing strings.

Theme and token definitions now belong in `lib/theme/`. UI code should consume them through `context.appScheme`, `context.appText`, and `context.appColors`. Direct `AppThemeColors` and `AppTextStyles` references are compatibility aliases that should only shrink over time, not be added back into non-theme UI code.
