#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 --staged | --range [from-ref] [to-ref] | --all" >&2
  exit 1
}

if [ "$#" -eq 0 ]; then
  usage
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

changed_files=()
scan_mode=""
range_from=""
range_to=""
theme_definition_roots=(
  "lib/theme/"
)

collect_changed_files() {
  while IFS= read -r file_path; do
    if [ -n "$file_path" ]; then
      changed_files+=("$file_path")
    fi
  done
}

is_theme_definition_allowlisted() {
  local file_path="$1"

  for allowed_path in "${theme_definition_roots[@]}"; do
    if [[ "$file_path" == "$allowed_path"* ]]; then
      return 0
    fi
  done

  return 1
}

report_matches() {
  local severity="$1"
  local heading="$2"
  local file_path="$3"
  local matches="$4"

  echo "$severity: $heading"
  echo "  $file_path"
  while IFS= read -r match_line; do
    if [ -n "$match_line" ]; then
      echo "    $match_line"
    fi
  done <<< "$matches"
}

policy_matches() {
  local file_path="$1"
  local pattern="$2"

  if [ "$scan_mode" = "all" ]; then
    grep -nE "$pattern" "$file_path" || true
    return
  fi

  local diff_cmd=()
  case "$scan_mode" in
    staged)
      diff_cmd=(git diff --cached --unified=0 -- "$file_path")
      ;;
    range)
      diff_cmd=(git diff --unified=0 "$range_from" "$range_to" -- "$file_path")
      ;;
    *)
      return
      ;;
  esac

  "${diff_cmd[@]}" | awk '
    /^@@ / {
      if (match($0, /\+[0-9]+/)) {
        line = substr($0, RSTART + 1, RLENGTH - 1) + 0
      }
      next
    }
    /^\+\+\+/ { next }
    /^\+/ {
      print line ":" substr($0, 2)
      line++
      next
    }
    /^ / {
      line++
      next
    }
  ' | grep -E "$pattern" || true
}

case "$1" in
  --staged)
    scan_mode="staged"
    shift
    collect_changed_files < <(
      git diff --cached --name-only --diff-filter=ACMR -- '*.dart'
    )
    ;;
  --range)
    scan_mode="range"
    if [ "$#" -ne 3 ]; then
      usage
    fi
    range_from="$2"
    range_to="$3"
    collect_changed_files < <(
      git diff --name-only --diff-filter=ACMR "$range_from" "$range_to" -- '*.dart'
    )
    ;;
  --all)
    scan_mode="all"
    shift
    collect_changed_files < <(find lib -name '*.dart' -type f | sort)
    ;;
  *)
    usage
    ;;
esac

if [ "${#changed_files[@]}" -eq 0 ]; then
  echo "No changed Dart files to check for policy violations."
  exit 0
fi

echo "Checking changed Dart files for UI policy violations:"
printf '  %s\n' "${changed_files[@]}"

error_count=0
warning_count=0

for file_path in "${changed_files[@]}"; do
  if [[ "$file_path" != lib/*.dart ]]; then
    continue
  fi

  with_opacity_matches=$(grep -nE '\.withOpacity\(' "$file_path" || true)
  if [ -n "$with_opacity_matches" ]; then
    report_matches \
      "ERROR" \
      "Deprecated color API usage; replace with withValues(alpha: ...)" \
      "$file_path" \
      "$with_opacity_matches"
    error_count=$((error_count + 1))
  fi

  if ! is_theme_definition_allowlisted "$file_path"; then
    raw_color_matches=$(grep -nE '\b(Colors|CupertinoColors)\.' "$file_path" || true)
    if [ -n "$raw_color_matches" ]; then
      report_matches \
        "ERROR" \
        "Raw framework color usage is only allowed in lib/theme/" \
        "$file_path" \
        "$raw_color_matches"
      error_count=$((error_count + 1))
    fi

    hardcoded_color_matches=$(grep -nE 'Color\(0x[0-9A-Fa-f]+\)|Color\.fromARGB\([[:space:]]*[0-9]+[[:space:]]*,[[:space:]]*[0-9]+[[:space:]]*,[[:space:]]*[0-9]+[[:space:]]*,[[:space:]]*[0-9]+[[:space:]]*\)|Color\.fromRGBO\([[:space:]]*[0-9]+[[:space:]]*,[[:space:]]*[0-9]+[[:space:]]*,[[:space:]]*[0-9]+[[:space:]]*,[[:space:]]*(0(\.[0-9]+)?|1(\.0+)?)' "$file_path" || true)
    if [ -n "$hardcoded_color_matches" ]; then
      report_matches \
        "ERROR" \
        "Hardcoded color constructors are only allowed in lib/theme/" \
        "$file_path" \
        "$hardcoded_color_matches"
      error_count=$((error_count + 1))
    fi

    raw_style_matches=$(grep -nE '\b(TextStyle|TextTheme|ColorScheme|ThemeData)\(' "$file_path" || true)
    if [ -n "$raw_style_matches" ]; then
      report_matches \
        "ERROR" \
        "Theme-only styling: text and theme definitions must live in lib/theme/" \
        "$file_path" \
        "$raw_style_matches"
      error_count=$((error_count + 1))
    fi

    compatibility_alias_matches=$(policy_matches "$file_path" '(^|[^[:alnum:]_])(AppThemeColors|AppTextStyles)\.')
    if [ -n "$compatibility_alias_matches" ]; then
      report_matches \
        "ERROR" \
        "Direct AppThemeColors/AppTextStyles usage is blocked outside lib/theme/; use context.appScheme/appText/appColors" \
        "$file_path" \
        "$compatibility_alias_matches"
      error_count=$((error_count + 1))
    fi
  fi

  inline_text_matches=$(grep -nE "Text\(\s*(const\s+)?['\"]|label:\s*['\"]|placeholder:\s*['\"]|semanticLabel:\s*['\"]|tooltip:\s*['\"]" "$file_path" || true)
  if [ -n "$inline_text_matches" ]; then
    report_matches \
      "WARNING" \
      "Likely inline user-facing strings; prefer centralizing strings in the next refactor" \
      "$file_path" \
      "$inline_text_matches"
    warning_count=$((warning_count + 1))
  fi

done

if [ "$warning_count" -gt 0 ]; then
  echo "Policy warnings: $warning_count"
fi

if [ "$error_count" -gt 0 ]; then
  echo "Policy errors: $error_count"
  exit 1
fi

echo "No blocking UI policy violations found."
