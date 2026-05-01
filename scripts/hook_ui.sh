#!/usr/bin/env bash

if [ -n "${ZENITH_HOOK_UI_SH:-}" ]; then
  return 0
fi
ZENITH_HOOK_UI_SH=1

hook_ui_is_tty() {
  [ -t 1 ] && [ -z "${CI:-}" ]
}

hook_ui_color_enabled() {
  hook_ui_is_tty
}

hook_ui_color() {
  local code="$1"
  if hook_ui_color_enabled; then
    printf '\033[%sm' "$code"
  fi
}

hook_ui_reset() {
  hook_ui_color '0'
}

hook_ui_dim() {
  hook_ui_color '2'
}

hook_ui_bold() {
  hook_ui_color '1'
}

hook_ui_red() {
  hook_ui_color '31'
}

hook_ui_green() {
  hook_ui_color '32'
}

hook_ui_yellow() {
  hook_ui_color '33'
}

hook_ui_blue() {
  hook_ui_color '34'
}

hook_ui_magenta() {
  hook_ui_color '35'
}

hook_ui_cyan() {
  hook_ui_color '36'
}

hook_ui_section() {
  local title="$1"
  printf '%s%s%s %s%s%s\n' \
    "$(hook_ui_bold)" \
    "$(hook_ui_blue)" \
    "$title" \
    "$(hook_ui_dim)" \
    "checks" \
    "$(hook_ui_reset)"
}

hook_ui_spinner() {
  local pid="$1"
  local label="$2"
  local accent="$3"
  local frames=( '|' '/' '-' '\\' )
  local index=0

  while kill -0 "$pid" >/dev/null 2>&1; do
    printf '\r%s%s%s %s%s%s' \
      "$(hook_ui_dim)" \
      "${frames[$index]}" \
      "$(hook_ui_reset)" \
      "$accent" \
      "$label" \
      "$(hook_ui_reset)"
    index=$(( (index + 1) % 4 ))
    sleep 0.08
  done

  printf '\r\033[2K'
}

hook_ui_run() {
  local label="$1"
  local accent="$2"
  shift 2

  local output_file
  output_file=$(mktemp)

  if hook_ui_is_tty; then
    "$@" >"$output_file" 2>&1 &
    local command_pid=$!
    hook_ui_spinner "$command_pid" "$label" "$accent"
    local status=0
    if ! wait "$command_pid"; then
      status=$?
    fi

    if [ "$status" -eq 0 ]; then
      printf '%sOK%s   %s%s%s\n' \
        "$(hook_ui_green)" \
        "$(hook_ui_reset)" \
        "$accent" \
        "$label" \
        "$(hook_ui_reset)"
      rm -f "$output_file"
      return 0
    fi

    printf '%sFAIL%s %s%s%s\n' \
      "$(hook_ui_red)" \
      "$(hook_ui_reset)" \
      "$accent" \
      "$label" \
      "$(hook_ui_reset)"
    cat "$output_file"
    rm -f "$output_file"
    return "$status"
  fi

  if "$@" >"$output_file" 2>&1; then
    printf '%sOK%s   %s\n' \
      "$(hook_ui_green)" \
      "$(hook_ui_reset)" \
      "$label"
    rm -f "$output_file"
    return 0
  fi

  local status=$?
  printf '%sFAIL%s %s\n' \
    "$(hook_ui_red)" \
    "$(hook_ui_reset)" \
    "$label"
  cat "$output_file"
  rm -f "$output_file"
  return "$status"
}