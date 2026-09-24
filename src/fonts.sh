#!/usr/bin/env bash
set -Eeuo pipefail

declare -g TEXTFORGE_ROOT="${TEXTFORGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
declare -g FONTS_DIR="${TEXTFORGE_ROOT}/fonts"
declare -gA FONT_GLYPHS=()
declare -ga FONT_LOADED_LIST=()
declare -ga TEXTFORGE_BUILTIN_FONTS=(block banner digital small shadow rounded slant compact retro minimal double outline)

trim_string() {
  local str="$1"
  str="${str%$'\r'}"
  str="${str%$'\n'}"
  str="${str#${str%%[![:space:]]*}}"
  str="${str%${str##*[![:space:]]}}"
  printf '%s' "$str"
}

load_font() {
  local font_name="$1"
  local font_file="$FONTS_DIR/${font_name}.font"

  if [[ ! -f "$font_file" ]]; then
    return 1
  fi

  for loaded in "${FONT_LOADED_LIST[@]}"; do
    if [[ "$loaded" == "$font_name" ]]; then
      return 0
    fi
  done

  local current_char=""
  local current_glyph=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    if [[ -z "$line" || "$line" == \#* ]]; then
      continue
    fi

    if [[ "$line" =~ ^@(.+)$ ]]; then
      if [[ -n "$current_char" ]]; then
        FONT_GLYPHS["${font_name}_${current_char}"]="$current_glyph"
      fi
      current_char="$(trim_string "${BASH_REMATCH[1]}")"
      current_glyph=""
      continue
    fi

    if [[ -n "$current_char" ]]; then
      if [[ -z "$current_glyph" ]]; then
        current_glyph="$line"
      else
        current_glyph+=$'\n'"$line"
      fi
    fi
  done < "$font_file"

  if [[ -n "$current_char" ]]; then
    FONT_GLYPHS["${font_name}_${current_char}"]="$current_glyph"
  fi

  FONT_LOADED_LIST+=("$font_name")
  return 0
}

builtin_shadow_glyph() {
  local glyph="$1"
  local -a lines=()
  local -a out=()
  local i

  IFS=$'\n' read -r -a lines <<< "$glyph"
  for ((i=0; i<${#lines[@]}; i++)); do
    out[i]="${lines[i]}  ."
  done
  printf '%s\n' "${out[@]}"
}

builtin_double_glyph() {
  local glyph="$1"
  local -a lines=()
  local -a out=()
  local i j

  IFS=$'\n' read -r -a lines <<< "$glyph"
  for ((i=0; i<${#lines[@]}; i++)); do
    local doubled=""
    for ((j=0; j<${#lines[i]}; j++)); do
      doubled+="${lines[i]:j:1}${lines[i]:j:1}"
    done
    out[i]="$doubled"
  done
  printf '%s\n' "${out[@]}"
}

builtin_slope_glyph() {
  local glyph="$1"
  local -a lines=()
  local -a out=()
  local i j

  IFS=$'\n' read -r -a lines <<< "$glyph"
  for ((i=0; i<${#lines[@]}; i++)); do
    out[i]=""
    for ((j=0; j<${#lines[i]}; j++)); do
      local ch="${lines[i]:j:1}"
      if [[ "$ch" == " " ]]; then
        out[i]="${out[i]} "
      elif (( j % 2 == 0 )); then
        out[i]="${out[i]}/"
      else
        out[i]="${out[i]}\\"
      fi
    done
  done
  printf '%s\n' "${out[@]}"
}

builtin_outline_glyph() {
  local glyph="$1"
  local -a lines=()
  local -a out=()
  local i j

  IFS=$'\n' read -r -a lines <<< "$glyph"
  for ((i=0; i<${#lines[@]}; i++)); do
    out[i]="${lines[i]}"
    for ((j=0; j<${#out[i]}; j++)); do
      local ch="${out[i]:j:1}"
      if [[ "$ch" == "#" ]]; then
        out[i]="${out[i]:0:j}█${out[i]:$((j+1))}"
      fi
    done
  done
  printf '%s\n' "${out[@]}"
}

builtin_generate_glyph() {
  local font_name="$1"
  local char="$2"
  local base_glyph

  base_glyph="$(get_glyph "$char" block 2>/dev/null || get_glyph '?' block 2>/dev/null || printf '█\n█\n█')"

  case "$font_name" in
    shadow)
      builtin_shadow_glyph "$base_glyph"
      ;;
    rounded)
      printf '%s\n' "$base_glyph" | sed 's/##/██/g; s/  /  /g'
      ;;
    slant)
      builtin_slope_glyph "$base_glyph"
      ;;
    double)
      builtin_double_glyph "$base_glyph"
      ;;
    outline)
      builtin_outline_glyph "$base_glyph"
      ;;
    retro)
      printf '%s\n' "$base_glyph" | sed 's/#/█/g; s/ /./g'
      ;;
    compact)
      get_glyph "$char" small 2>/dev/null || printf '%s\n' "$base_glyph"
      ;;
    minimal)
      get_glyph "$char" small 2>/dev/null || printf '%s\n' "$base_glyph"
      ;;
    *)
      return 1
      ;;
  esac
}

get_glyph() {
  local char="$1"
  local font_name="${2:-block}"
  local key

  char="${char^^}"
  if [[ "$char" == " " ]]; then
    char="SPACE"
  fi

  if [[ -n "$font_name" ]]; then
    if ! [[ " ${TEXTFORGE_BUILTIN_FONTS[*]} " =~ " ${font_name} " ]]; then
      font_name="block"
    fi
  else
    font_name="block"
  fi

  if [[ -f "$FONTS_DIR/${font_name}.font" ]]; then
    load_font "$font_name" || return 1
    key="${font_name}_${char}"
    if [[ -n "${FONT_GLYPHS[$key]:-}" ]]; then
      printf '%s' "${FONT_GLYPHS[$key]}"
      return 0
    fi

    key="${font_name}_?"
    if [[ -n "${FONT_GLYPHS[$key]:-}" ]]; then
      printf '%s' "${FONT_GLYPHS[$key]}"
      return 0
    fi
  fi

  if [[ "$font_name" == "block" ]]; then
    load_font "$font_name" || return 1
    key="${font_name}_${char}"
    if [[ -n "${FONT_GLYPHS[$key]:-}" ]]; then
      printf '%s' "${FONT_GLYPHS[$key]}"
      return 0
    fi
    key="${font_name}_?"
    if [[ -n "${FONT_GLYPHS[$key]:-}" ]]; then
      printf '%s' "${FONT_GLYPHS[$key]}"
      return 0
    fi
  fi

  local generated
  generated="$(builtin_generate_glyph "$font_name" "$char" 2>/dev/null || true)"
  if [[ -n "$generated" ]]; then
    printf '%s' "$generated"
    return 0
  fi

  local fallback
  fallback="$(get_glyph "$char" block 2>/dev/null || true)"
  if [[ -n "$fallback" ]]; then
    printf '%s' "$fallback"
    return 0
  fi

  return 1
}

get_available_fonts() {
  local -A seen=()
  local font_name
  local font_file

  for font_name in "${TEXTFORGE_BUILTIN_FONTS[@]}"; do
    seen["$font_name"]=1
  done

  if [[ -d "$FONTS_DIR" ]]; then
    for font_file in "$FONTS_DIR"/*.font; do
      [[ -f "$font_file" ]] || continue
      font_name="$(basename "$font_file" .font)"
      seen["$font_name"]=1
    done
  fi

  for font_name in "${!seen[@]}"; do
    printf '%s\n' "$font_name"
  done | sort
}

font_exists() {
  local font_name="${1:-block}"
  local available
  available="$(get_available_fonts)"
  if printf '%s\n' "$available" | grep -Fxq "$font_name"; then
    return 0
  fi
  return 1
}

get_font_height() {
  local font_name="${1:-block}"
  local glyph
  glyph="$(get_glyph 'A' "$font_name" 2>/dev/null || printf '')"
  if [[ -z "$glyph" ]]; then
    printf '6'
    return 0
  fi
  printf '%s' "$(printf '%s\n' "$glyph" | wc -l | tr -d ' ')"
}

get_glyph_width() {
  local glyph="$1"
  local first_line
  first_line="$(printf '%s\n' "$glyph" | head -n 1)"
  printf '%s' "${#first_line}"
}
