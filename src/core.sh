#!/usr/bin/env bash
set -Eeuo pipefail

TEXTFORGE_VERSION="2.0.0"
TEXTFORGE_STYLE_DEFAULT="block"
TEXTFORGE_COLOR_DEFAULT="cyan"
TEXTFORGE_DATA_DIR="${XDG_DATA_HOME:-${HOME:-/tmp}/.local/share}/textforge"

usage() {
  cat <<'EOF'
TextForge 2.0.0

Generate ASCII banners in your terminal.

Usage:
  textforge [options] "text"
  textforge -f FONT "text"
  textforge --list-fonts
  textforge --colors

Options:
  -f, --font FONT        Use a font
  -n, --no-color         Disable ANSI colors
      --color COLOR      Apply a foreground color
  -a, --align MODE       Align text
  -w, --width N          Set width
  -s, --spacing N        Set spacing
      --list-fonts       List fonts
      --colors           List colors
  -v, --version          Show version
  -h, --help             Show help

Examples:
  textforge "Hello"
  textforge -f digital "Hello"
  textforge --color cyan "Hello"
  textforge --list-fonts
EOF
}

version() {
  printf 'TextForge %s\n' "$TEXTFORGE_VERSION"
}

error() {
  local message="$1"
  local show_usage="${2:-}"

  printf 'Error: %s\n' "$message" >&2
  if [[ "$show_usage" == "usage" ]]; then
    printf '\nRun '\''textforge --help'\'' for usage.\n' >&2
  fi
  exit 1
}

trim_text() {
  local text="$1"
  text="${text#${text%%[![:space:]]*}}"
  text="${text%${text##*[![:space:]]}}"
  printf '%s' "$text"
}

is_valid_style() {
  case "$1" in
    block|small|minimal|banner|slant|shadow|digital) return 0 ;;
    *) return 1 ;;
  esac
}

choose_random_style() {
  local styles=(block small minimal banner slant shadow digital)
  printf '%s' "${styles[$RANDOM % ${#styles[@]}]}"
}

main() {
  local -a positional=()
  local save_name=""
  local load_name=""
  local style=""
  local random_mode=0
  local list_mode=0
  local help_mode=0
  local version_mode=0
  local no_color=0
  local raw_text=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--style)
        if [[ $# -lt 2 ]]; then
          error "missing value for --style" "usage"
        fi
        style="$2"
        shift 2
        ;;
      -S|--save)
        if [[ $# -lt 2 ]]; then
          error "missing value for --save" "usage"
        fi
        save_name="$2"
        shift 2
        ;;
      -L|--load)
        if [[ $# -lt 2 ]]; then
          error "missing value for --load" "usage"
        fi
        load_name="$2"
        shift 2
        ;;
      -l|--list)
        list_mode=1
        shift
        ;;
      -r|--random)
        random_mode=1
        shift
        ;;
      -n|--no-color)
        export NO_COLOR=1
        no_color=1
        shift
        ;;
      -v|--version)
        version_mode=1
        shift
        ;;
      -h|--help)
        help_mode=1
        shift
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        error "unknown option '$1'" "usage"
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  detect_color_capabilities

  if [[ "$help_mode" -eq 1 ]]; then
    usage
    exit 0
  fi

  if [[ "$version_mode" -eq 1 ]]; then
    version
    exit 0
  fi

  if [[ "$list_mode" -eq 1 ]]; then
    list_styles
    exit 0
  fi

  if [[ -n "$save_name" ]]; then
    if [[ ${#positional[@]} -eq 0 ]]; then
      error "missing text for --save" "usage"
    fi
    raw_text="${positional[*]}"
    raw_text="$(trim_text "$raw_text")"
    if [[ -z "$raw_text" ]]; then
      error "missing text for --save" "usage"
    fi
    save_banner "$save_name" "$raw_text" "${style:-block}"
    exit 0
  fi

  if [[ -n "$load_name" ]]; then
    load_banner "$load_name"
    exit 0
  fi

  if [[ "$random_mode" -eq 1 ]]; then
    raw_text="${positional[*]:-TextForge}"
    raw_text="$(trim_text "$raw_text")"
    if [[ -z "$raw_text" ]]; then
      raw_text="TextForge"
    fi
    style="${style:-$(choose_random_style)}"
    if ! is_valid_style "$style"; then
      printf 'Error: unknown style '\''%s'\''\n\nAvailable styles:\n  block\n  small\n  minimal\n  banner\n  slant\n  shadow\n  digital\n' "$style" >&2
      exit 1
    fi
    render_banner "$raw_text" "$style" "${TEXTFORGE_COLOR_DEFAULT:-cyan}"
    exit 0
  fi

  if [[ ${#positional[@]} -eq 0 ]]; then
    error "missing text" "usage"
  fi

  raw_text="${positional[*]}"
  raw_text="$(trim_text "$raw_text")"
  if [[ -z "$raw_text" ]]; then
    error "missing text" "usage"
  fi

  style="${style:-$TEXTFORGE_STYLE_DEFAULT}"
  if ! is_valid_style "$style"; then
    printf 'Error: unknown style '\''%s'\''\n\nAvailable styles:\n  block\n  small\n  minimal\n  banner\n  slant\n  shadow\n  digital\n' "$style" >&2
    exit 1
  fi

  render_banner "$raw_text" "$style" "${TEXTFORGE_COLOR_DEFAULT:-cyan}"
}
