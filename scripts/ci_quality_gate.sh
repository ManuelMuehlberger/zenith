#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

event_name=${GITHUB_EVENT_NAME:-}
head_sha=${GITHUB_SHA:-HEAD}
pull_request_base_sha=${GITHUB_BASE_SHA:-}
push_before_sha=${GITHUB_BEFORE_SHA:-}
main_ref=${CI_MAIN_REF:-origin/main}
zero_sha=0000000000000000000000000000000000000000

commit_exists() {
  local ref="$1"
  [ -n "$ref" ] && git cat-file -e "$ref^{commit}" >/dev/null 2>&1
}

resolve_base_sha() {
  if [ "$event_name" = "pull_request" ] && commit_exists "$pull_request_base_sha"; then
    printf '%s\n' "$pull_request_base_sha"
    return
  fi

  if commit_exists "$push_before_sha" && [ "$push_before_sha" != "$zero_sha" ]; then
    printf '%s\n' "$push_before_sha"
    return
  fi

  if git rev-parse --verify "$main_ref" >/dev/null 2>&1; then
    git merge-base "$main_ref" "$head_sha"
    return
  fi

  if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    git rev-parse HEAD~1
    return
  fi

  printf '%s\n' ""
}

base_sha=$(resolve_base_sha)

if [ -z "$base_sha" ]; then
  echo "Unable to determine a diff base for CI quality checks." >&2
  exit 1
fi

echo "Running diff-aware quality checks for range: $base_sha..$head_sha"

"$repo_root/scripts/check_changed_dart_policy.sh" --range "$base_sha" "$head_sha"
python3 "$repo_root/scripts/check_changed_dart_maintainability.py" --range "$base_sha" "$head_sha"
python3 "$repo_root/scripts/check_changed_dart_coverage.py" --range "$base_sha" "$head_sha"