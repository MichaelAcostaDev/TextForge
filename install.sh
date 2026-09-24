#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
SHARE_DIR="${HOME}/.local/share/textforge"
TARGET_BIN="$TARGET_DIR/textforge"

info() { printf '%s\n' "$1"; }
warn() { printf 'Warning: %s\n' "$1" >&2; }
error() { printf 'Error: %s\n' "$1" >&2; exit 1; }

shell_rc_file() {
  local shell_name="${1:-${SHELL##*/}}"
  case "$shell_name" in
    bash) printf '%s/.bashrc' "$HOME" ;;
    zsh) printf '%s/.zshrc' "$HOME" ;;
    *) printf '%s/.profile' "$HOME" ;;
  esac
}

append_shell_path() {
  local shell_name="${1:-${SHELL##*/}}"
  local path_line="export PATH=\"$TARGET_DIR:\$PATH\""
  local rc_file
  rc_file="$(shell_rc_file "$shell_name")"

  if [[ ! -f "$rc_file" ]]; then
    touch "$rc_file"
  fi

  if ! grep -Fqx "$path_line" "$rc_file" 2>/dev/null; then
    printf '\n%s\n' "$path_line" >> "$rc_file"
    info "Added PATH export to $rc_file"
  fi
}

if [[ ! -d "$PROJECT_ROOT" ]]; then
  error "project directory not found: $PROJECT_ROOT"
fi

if ! command -v bash >/dev/null 2>&1; then
  error "bash is required but not installed"
fi

mkdir -p "$TARGET_DIR" "$SHARE_DIR"
if [[ ! -w "$TARGET_DIR" || ! -w "$SHARE_DIR" ]]; then
  error "cannot write to $TARGET_DIR or $SHARE_DIR; fix permissions and retry"
fi

cp -R "$PROJECT_ROOT/src" "$SHARE_DIR/"
cp -R "$PROJECT_ROOT/fonts" "$SHARE_DIR/"
cp "$PROJECT_ROOT/textforge" "$SHARE_DIR/textforge"
cp "$PROJECT_ROOT/install.sh" "$SHARE_DIR/install.sh"
cp "$PROJECT_ROOT/uninstall.sh" "$SHARE_DIR/uninstall.sh"
cp "$PROJECT_ROOT/LICENSE" "$SHARE_DIR/LICENSE"
cp "$PROJECT_ROOT/README.md" "$SHARE_DIR/README.md"
cp -R "$PROJECT_ROOT/tests" "$SHARE_DIR/tests"

cat > "$TARGET_BIN" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
export TEXTFORGE_ROOT="${SHARE_DIR}"
exec "${SHARE_DIR}/textforge" "\$@"
EOF

chmod +x "$TARGET_BIN" "$SHARE_DIR/textforge" "$SHARE_DIR/install.sh" "$SHARE_DIR/uninstall.sh" "$SHARE_DIR/tests/run.sh"

if [[ "${1:-}" == "--shell" ]]; then
  shell_name="${2:-${SHELL##*/}}"
  append_shell_path "$shell_name"
fi

info "TextForge installed successfully."
info ""
info "Installed files:"
info "  $TARGET_BIN"
info "  $SHARE_DIR"
info ""
if [[ ":$PATH:" != *":$TARGET_DIR:"* ]]; then
  info "Add $TARGET_DIR to your PATH to use 'textforge' from new terminals."
  info "In your current shell, run:"
  info "  export PATH=\"$HOME/.local/bin:\$PATH\""
  info ""
fi
info "Verify with:"
info "  textforge --help"
info "  textforge --version"
info "  textforge \"Hello\""
