#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

echo "Checking repository formatting for lib/ and test/."
dart format --output=none --set-exit-if-changed lib test

echo "Running full flutter analyze."
flutter analyze
