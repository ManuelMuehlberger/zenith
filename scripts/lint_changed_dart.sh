#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 --staged | --range [from-ref] [to-ref]" >&2
  exit 1
}

if [ "$#" -eq 0 ]; then
  usage
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

changed_files=()

collect_changed_files() {
  while IFS= read -r file_path; do
    if [ -n "$file_path" ]; then
      changed_files+=("$file_path")
    fi
  done
}

case "$1" in
  --staged)
    shift
    collect_changed_files < <(
      git diff --cached --name-only --diff-filter=ACMR -- '*.dart'
    )
    ;;
  --range)
    if [ "$#" -ne 3 ]; then
      usage
    fi
    collect_changed_files < <(
      git diff --name-only --diff-filter=ACMR "$2" "$3" -- '*.dart'
    )
    ;;
  *)
    usage
    ;;
esac

if [ "${#changed_files[@]}" -eq 0 ]; then
  echo "No changed Dart files to lint."
  exit 0
fi

echo "Linting changed Dart files:"
printf '  %s\n' "${changed_files[@]}"

dart format --output=none --set-exit-if-changed "${changed_files[@]}"
flutter analyze "${changed_files[@]}"
