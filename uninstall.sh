#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_BIN="${HOME}/.local/bin/textforge"
SHARE_DIR="${HOME}/.local/share/textforge"

info() { printf '%s\n' "$1"; }
warn() { printf 'Warning: %s\n' "$1" >&2; }

if [[ -f "$TARGET_BIN" ]]; then
  rm -f "$TARGET_BIN"
  info "Removed textforge from $TARGET_BIN"
else
  warn "textforge is not installed at $TARGET_BIN"
fi

if [[ -d "$SHARE_DIR" ]]; then
  rm -rf "$SHARE_DIR"
  info "Removed TextForge data from $SHARE_DIR"
fi

exit 0
