#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

head_sha=${GITHUB_SHA:-HEAD}
base_sha=$("$repo_root/scripts/resolve_diff_base.sh" "$head_sha")

echo "Running diff-aware quality checks for range: $base_sha..$head_sha"

"$repo_root/scripts/check_changed_dart_policy.sh" --range "$base_sha" "$head_sha"
python3 "$repo_root/scripts/check_changed_dart_maintainability.py" --range "$base_sha" "$head_sha"
python3 "$repo_root/scripts/check_changed_dart_coverage.py" --range "$base_sha" "$head_sha"
