#!/usr/bin/env bash
set -Eeuo pipefail

show_help() {
  cat <<EOF
textForge ${TEXTFORGE_VERSION:-2.0.0}

Usage:
  textforge [options] "text"
  textforge -f FONT "text"
  textforge --list-fonts
  textforge --colors

Options:
  -f, --font FONT        Use a specific font (default: block)
  -n, --no-color         Disable ANSI color output
      --color COLOR      Apply a foreground color (default: default)
  -a, --align MODE       Align text: left, center, right (default: left)
  -w, --width N          Set output width
  -s, --spacing N        Set character spacing
      --list-fonts       List available fonts
      --colors           List available colors
  -l                     Alias for --list-fonts
  -v, --version          Show version information
  -h, --help             Show this help message

Examples:
  textforge "Hello"
  textforge -f digital "Hello"
  textforge --color cyan "Hello world"
  textforge --list-fonts
EOF
}

show_version() {
  printf '%s %s\n' "${TEXTFORGE_NAME:-textForge}" "${TEXTFORGE_VERSION:-2.0.0}"
}

list_fonts() {
  printf 'Available fonts:\n'
  while IFS= read -r font; do
    [[ -n "$font" ]] || continue
    printf '  %s\n' "$font"
  done < <(get_available_fonts)
}

list_colors() {
  printf 'Available colors:\n'
  while IFS= read -r color; do
    [[ -n "$color" ]] || continue
    printf '  %s\n' "$color"
  done < <(list_available_colors)
}

parse_cli() {
  local font="block"
  local align="left"
  local width="0"
  local spacing="1"
  local color="default"
  local text=""
  local -a positional=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        return 0
        ;;
      -v|--version)
        show_version
        return 0
        ;;
      -l|--list-fonts)
        list_fonts
        return 0
        ;;
      --colors)
        list_colors
        return 0
        ;;
      -f|--font)
        if [[ $# -lt 2 ]]; then
          printf 'Error: %s requires a font name\n' "$1" >&2
          return 1
        fi
        font="$2"
        shift 2
        ;;
      -a|--align)
        if [[ $# -lt 2 ]]; then
          printf 'Error: %s requires a value\n' "$1" >&2
          return 1
        fi
        align="${2,,}"
        shift 2
        ;;
      -w|--width)
        if [[ $# -lt 2 ]]; then
          printf 'Error: %s requires a numeric width\n' "$1" >&2
          return 1
        fi
        width="$2"
        shift 2
        ;;
      -s|--spacing)
        if [[ $# -lt 2 ]]; then
          printf 'Error: %s requires a numeric spacing\n' "$1" >&2
          return 1
        fi
        spacing="$2"
        shift 2
        ;;
      -n|--no-color)
        export TEXTFORGE_NO_COLOR=1
        shift
        ;;
      --color)
        if [[ $# -lt 2 ]]; then
          printf 'Error: --color requires a color name\n' >&2
          return 1
        fi
        color="$2"
        shift 2
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        printf 'Error: unknown option: %s\n' "$1" >&2
        printf 'Run "textforge --help" for usage.\n' >&2
        return 1
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#positional[@]} -gt 0 ]]; then
    text="${positional[*]}"
  fi

  detect_textforge_color_capabilities

  if [[ -z "$text" ]]; then
    printf 'Error: no text provided\n' >&2
    printf 'Run "textforge --help" for usage.\n' >&2
    return 1
  fi

  if ! font_exists "$font"; then
    printf 'Error: unknown font: %s\n' "$font" >&2
    printf 'Run "textforge --list-fonts" to list available fonts.\n' >&2
    return 1
  fi

  case "$align" in
    left|center|right)
      ;;
    *)
      printf 'Error: unsupported alignment: %s\n' "$align" >&2
      return 1
      ;;
  esac

  render_colored "$text" "$font" "$color" "$width" "$align" "$spacing"
}

font_exists() {
  local font_name="${1:-block}"
  get_available_fonts | grep -Fxq "$font_name"
}
