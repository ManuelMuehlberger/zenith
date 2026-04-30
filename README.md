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

The hook chain now does two things on changed Dart files:

- Runs formatting and analyzer checks.
- Runs a UI policy scan with a small allowlist.

Blocking policy checks:

- New `withOpacity(...)` usage in `lib/`.
- New raw `Colors.*` or `CupertinoColors.*` usage in `lib/`, except in `lib/main.dart` and `lib/constants/app_constants.dart`.

Warning-only policy checks:

- Likely inline user-facing strings.
- `TextStyle(...)` lines that use raw framework colors directly.

The color allowlist is intentionally small to push new styling work toward theme and token refactors.
