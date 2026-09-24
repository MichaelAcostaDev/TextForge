#!/usr/bin/env bash
set -Eeuo pipefail

TEXTFORGE_USE_COLOR="${TEXTFORGE_USE_COLOR:-1}"
TEXTFORGE_COLOR_DEPTH="${TEXTFORGE_COLOR_DEPTH:-8}"

list_available_colors() {
  printf '%s\n' \
    black red green yellow blue magenta cyan white default \
    bright-red bright-green bright-yellow bright-blue bright-magenta bright-cyan bright-white
}

normalize_color_name() {
  local name="${1:-default}"
  name="${name,,}"
  name="${name//-/_}"
  case "$name" in
    gray|grey) printf '%s' 'white' ;;
    default) printf '%s' 'default' ;;
    bright_red) printf '%s' 'bright-red' ;;
    bright_green) printf '%s' 'bright-green' ;;
    bright_yellow) printf '%s' 'bright-yellow' ;;
    bright_blue) printf '%s' 'bright-blue' ;;
    bright_magenta) printf '%s' 'bright-magenta' ;;
    bright_cyan) printf '%s' 'bright-cyan' ;;
    bright_white) printf '%s' 'bright-white' ;;
    *) printf '%s' "$name" ;;
  esac
}

resolve_color_code() {
  local color_name="${1:-default}"
  local normalized
  normalized="$(normalize_color_name "$color_name")"

  case "$normalized" in
    black) printf '30' ;;
    red) printf '31' ;;
    green) printf '32' ;;
    yellow) printf '33' ;;
    blue) printf '34' ;;
    magenta) printf '35' ;;
    cyan) printf '36' ;;
    white) printf '37' ;;
    default) printf '39' ;;
    bright-red) printf '91' ;;
    bright-green) printf '92' ;;
    bright-yellow) printf '93' ;;
    bright-blue) printf '94' ;;
    bright-magenta) printf '95' ;;
    bright-cyan) printf '96' ;;
    bright-white) printf '97' ;;
    *) printf '39' ;;
  esac
}

ansi_escape() {
  local code="$1"
  if (( TEXTFORGE_USE_COLOR == 0 )); then
    printf ''
  else
    printf '\033[%sm' "$code"
  fi
}

ansi_fg() {
  local code="$1"
  printf '%s' "$(ansi_escape "$code")"
}

reset_color() {
  if (( TEXTFORGE_USE_COLOR == 0 )); then
    printf ''
  else
    printf '\033[0m'
  fi
}

detect_textforge_color_capabilities() {
  if [[ "${NO_COLOR:-0}" == "1" || "${TEXTFORGE_NO_COLOR:-0}" == "1" ]]; then
    TEXTFORGE_USE_COLOR=0
    TEXTFORGE_COLOR_DEPTH=0
    return
  fi

  if [[ ! -t 1 ]]; then
    TEXTFORGE_USE_COLOR=0
    TEXTFORGE_COLOR_DEPTH=0
    return
  fi

  if [[ -n "${TERM:-}" ]] && [[ "$TERM" == "dumb" ]]; then
    TEXTFORGE_USE_COLOR=0
    TEXTFORGE_COLOR_DEPTH=0
    return
  fi

  local colors=8
  if command -v tput >/dev/null 2>&1; then
    colors="$(tput colors 2>/dev/null || printf '8')"
  fi

  if [[ "$colors" =~ ^[0-9]+$ ]]; then
    TEXTFORGE_COLOR_DEPTH="$colors"
  else
    TEXTFORGE_COLOR_DEPTH=8
  fi

  if (( TEXTFORGE_COLOR_DEPTH < 8 )); then
    TEXTFORGE_USE_COLOR=0
  fi
}

apply_color_to_line() {
  local line="$1"
  local color_name="${2:-default}"
  local bold="${3:-0}"
  local dim="${4:-0}"
  local underline="${5:-0}"
  local reverse="${6:-0}"

  if (( TEXTFORGE_USE_COLOR == 0 )); then
    printf '%s' "$line"
    return
  fi

  local -a codes=()
  codes+=("$(resolve_color_code "$color_name")")
  if [[ "$bold" == "1" ]]; then codes+=("1"); fi
  if [[ "$dim" == "1" ]]; then codes+=("2"); fi
  if [[ "$underline" == "1" ]]; then codes+=("4"); fi
  if [[ "$reverse" == "1" ]]; then codes+=("7"); fi

  local IFS=';'
  printf '\033[%sm%s\033[0m' "${codes[*]}" "$line"
}

render_colorized_block() {
  local line="$1"
  local color_name="${2:-default}"
  local bold="${3:-0}"
  local dim="${4:-0}"
  local underline="${5:-0}"
  local reverse="${6:-0}"
  apply_color_to_line "$line" "$color_name" "$bold" "$dim" "$underline" "$reverse"
}
