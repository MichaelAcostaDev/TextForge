#!/usr/bin/env bash
set -Eeuo pipefail

trim_right() {
  local value="${1:-}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s' "$value"
}

pad_line() {
  local line="${1:-}"
  local width="${2:-0}"
  local align="${3:-left}"
  local length="${#line}"

  if (( width <= 0 || length >= width )); then
    printf '%s' "$line"
    return 0
  fi

  local remaining=$((width - length))
  local left_pad=0
  local right_pad=0

  case "$align" in
    left)
      right_pad=$remaining
      ;;
    right)
      left_pad=$remaining
      ;;
    center)
      left_pad=$((remaining / 2))
      right_pad=$((remaining - left_pad))
      ;;
    *)
      right_pad=$remaining
      ;;
  esac

  local left_spaces=""
  local right_spaces=""
  local i
  for ((i = 0; i < left_pad; i++)); do left_spaces+=" "; done
  for ((i = 0; i < right_pad; i++)); do right_spaces+=" "; done

  printf '%s%s%s' "$left_spaces" "$line" "$right_spaces"
}

render_text() {
  local text="${1:-}"
  local font_name="${2:-block}"
  local width="${3:-0}"
  local align="${4:-left}"
  local spacing="${5:-1}"
  local height i j char glyph
  local -a lines=()
  local -a glyph_lines=()

  [[ -n "$text" ]] || return 0
  height=$(get_font_height "$font_name")

  for ((i = 0; i < height; i++)); do
    lines[i]=""
  done

  for ((i = 0; i < ${#text}; i++)); do
    char="${text:i:1}"

    if [[ "$char" == " " ]]; then
      for ((j = 0; j < height; j++)); do
        local gap=""
        for ((k = 0; k < spacing; k++)); do gap+=" "; done
        lines[j]+="${gap}"
      done
      continue
    fi

    glyph="$(get_glyph "$char" "$font_name" 2>/dev/null || get_glyph "?" "$font_name" 2>/dev/null || printf '')"
    if [[ -z "$glyph" ]]; then
      for ((j = 0; j < height; j++)); do
        local gap=""
        for ((k = 0; k < spacing; k++)); do gap+=" "; done
        lines[j]+="${gap}"
      done
      continue
    fi

    glyph_lines=()
    while IFS= read -r gline || [[ -n "$gline" ]]; do
      glyph_lines+=("$gline")
    done <<< "$glyph"

    for ((j = 0; j < height; j++)); do
      local segment="${glyph_lines[j]:-}"
      lines[j]+="${segment}"
      if (( i < ${#text} - 1 )); then
        local gap=""
        for ((k = 0; k < spacing; k++)); do gap+=" "; done
        lines[j]+="${gap}"
      fi
    done
  done

  for ((i = 0; i < height; i++)); do
    lines[i]="$(trim_right "${lines[i]}")"
    if (( width > 0 )); then
      lines[i]="$(pad_line "${lines[i]}" "$width" "$align")"
    fi
    printf '%s\n' "${lines[i]}"
  done
}

render_colored() {
  local text="${1:-}"
  local font_name="${2:-block}"
  local color_name="${3:-default}"
  local width="${4:-0}"
  local align="${5:-left}"
  local spacing="${6:-1}"

  local output
  output="$(render_text "$text" "$font_name" "$width" "$align" "$spacing")"

  if [[ -n "$color_name" && "$color_name" != "none" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      printf '%s\n' "$(apply_color_to_line "$line" "$color_name")"
    done <<< "$output"
  else
    printf '%s\n' "$output"
  fi
}

get_terminal_width() {
  if [[ -t 1 ]]; then
    if command -v tput >/dev/null 2>&1; then
      tput cols 2>/dev/null || printf '80'
    elif [[ -n "${COLUMNS:-}" ]]; then
      printf '%s' "$COLUMNS"
    else
      printf '80'
    fi
  else
    printf '80'
  fi
}

will_fit_in_terminal() {
  local text="$1"
  local font_name="${2:-block}"
  local width max_width

  width="$(render_text "$text" "$font_name" | head -n 1 | wc -c | tr -d ' ')"
  max_width="$(get_terminal_width)"

  (( width <= max_width ))
}
