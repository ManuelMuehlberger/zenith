#!/usr/bin/env bash

set -euo pipefail

echo "Validating prebuilt CI image toolchain"
java -version
flutter --version
dart --version
flutter doctor -v

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
flutter test \
  test/services/insights/exercise_trend_provider_test.dart \
  test/services/insights/insights_timeframe_resolver_test.dart \
  test/services/insights/workout_trend_provider_test.dart
flutter build apk --debug