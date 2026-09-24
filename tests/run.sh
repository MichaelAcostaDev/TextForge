#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
  local name="$1"
  shift
  TESTS_RUN=$((TESTS_RUN + 1))
  if "$@" >/dev/null 2>&1; then
    printf "${GREEN}✓${NC} %s\n" "$name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    printf "${RED}✗${NC} %s\n" "$name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_root_exists() {
  [[ -x "$PROJECT_ROOT/textforge" ]]
}

test_help_output() {
  local output
  output=$(bash "$PROJECT_ROOT/textforge" --help 2>&1)
  [[ "$output" =~ Usage ]]
}

test_version_output() {
  local output
  output=$(bash "$PROJECT_ROOT/textforge" --version 2>&1)
  [[ "$output" =~ textForge|textforge ]]
}

test_font_list() {
  local output
  output=$(bash "$PROJECT_ROOT/textforge" --list-fonts 2>&1)
  [[ "$output" == *block* ]]
}

test_colors_list() {
  local output
  output=$(bash "$PROJECT_ROOT/textforge" --colors 2>&1)
  [[ "$output" == *cyan* ]]
}

test_render_basic() {
  local output
  output=$(bash "$PROJECT_ROOT/textforge" 'Hello' 2>&1)
  [[ -n "$output" ]]
}

test_no_color() {
  local output
  output=$(bash "$PROJECT_ROOT/textforge" --no-color 'Hello' 2>&1)
  [[ -n "$output" ]] && [[ "$output" != *$'\033'* ]]
}

test_invalid_font() {
  bash "$PROJECT_ROOT/textforge" -f no-such-font 'Hello' >/dev/null 2>&1
  test $? -ne 0
}

test_empty_text() {
  bash "$PROJECT_ROOT/textforge" '' >/dev/null 2>&1
  test $? -ne 0
}

test_multi_word_render() {
  local output
  output=$(bash "$PROJECT_ROOT/textforge" 'Hello world' 2>&1)
  [[ -n "$output" ]]
}

test_color_alias() {
  local output
  output=$(bash "$PROJECT_ROOT/textforge" --color cyan 'Hello' 2>&1)
  [[ -n "$output" ]]
}

printf "\n${BLUE}=== textForge CLI regression tests ===${NC}\n"

run_test "root command exists" test_root_exists
run_test "help output shows usage" test_help_output
run_test "version output contains textForge" test_version_output
run_test "font list works" test_font_list
run_test "colors list works" test_colors_list
run_test "basic render works" test_render_basic
run_test "no-color disables ANSI escapes" test_no_color
run_test "invalid font fails cleanly" test_invalid_font
run_test "empty text fails" test_empty_text
run_test "multiple words render" test_multi_word_render
run_test "textforge alias supports color" test_color_alias

printf "\n${BLUE}=== Test Summary ===${NC}\n"
printf "Tests run: %s\n" "$TESTS_RUN"
printf "${GREEN}Passed: %s${NC}\n" "$TESTS_PASSED"
if [[ "$TESTS_FAILED" -gt 0 ]]; then
  printf "${RED}Failed: %s${NC}\n" "$TESTS_FAILED"
  exit 1
fi
printf "${GREEN}All textForge tests passed!${NC}\n"
exit 0

