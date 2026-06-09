#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

head_ref=${1:-HEAD}
zero_sha=0000000000000000000000000000000000000000

commit_exists() {
  local ref="$1"
  [ -n "$ref" ] && git cat-file -e "$ref^{commit}" >/dev/null 2>&1
}

pull_request_base_sha=${GITHUB_BASE_SHA:-}
push_before_sha=${GITHUB_BEFORE_SHA:-}
main_ref=${CI_MAIN_REF:-origin/main}

if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ] && commit_exists "$pull_request_base_sha"; then
  printf '%s\n' "$pull_request_base_sha"
  exit 0
fi

if commit_exists "$push_before_sha" && [ "$push_before_sha" != "$zero_sha" ]; then
  printf '%s\n' "$push_before_sha"
  exit 0
fi

if git rev-parse --verify '@{upstream}' >/dev/null 2>&1; then
  printf '%s\n' '@{upstream}'
  exit 0
fi

default_remote_ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)
if [ -n "$default_remote_ref" ]; then
  printf '%s\n' "$default_remote_ref"
  exit 0
fi

if git rev-parse --verify "$main_ref" >/dev/null 2>&1; then
  git merge-base "$main_ref" "$head_ref"
  exit 0
fi

if git rev-parse --verify "${head_ref}~1" >/dev/null 2>&1; then
  git rev-parse "${head_ref}~1"
  exit 0
fi

echo "Unable to determine a diff base." >&2
exit 1
