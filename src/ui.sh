#!/usr/bin/env bash
set -Eeuo pipefail

textforge_banner() {
  cat <<'EOF'
  TextForge

  Create beautiful ASCII banners.
EOF
}

banner_intro() {
  if [[ -t 1 ]]; then
    printf '%s\n' "$(ansi_fg 36)TextForge$(reset_color)"
    printf '%s\n' "Create beautiful ASCII banners."
  else
    printf '%s\n' 'TextForge'
    printf '%s\n' 'Create beautiful ASCII banners.'
  fi
}
