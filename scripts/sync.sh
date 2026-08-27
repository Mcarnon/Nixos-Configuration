#!/usr/bin/env bash
# Sync / deploy this NixOS config to another machine over SSH + rsync
#
# Usage:
#   ./scripts/sync.sh push   [remote]   # push this machine's config to the remote
#   ./scripts/sync.sh pull   [remote]   # pull config from the remote to this machine
#   ./scripts/sync.sh deploy [remote]   # push + remote nixos-rebuild switch
#
# remote defaults to the SSH alias nixos-remote (see modules/nixos/network/openssh.nix)

set -euo pipefail

REMOTE="${2:-nixos-remote}"
# directory on the remote that holds the config (supports ~ expansion)
REMOTE_DIR="${REMOTE_DIR:-~/Nixos-Configuration}"

# repository root (one level above scripts/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RSYNC_EXCLUDES=(
  --exclude '.git'
  --exclude 'result'
  --exclude 'result-*'
  --exclude '.direnv'
)

usage() {
  echo "Usage: $0 {push|pull|deploy} [remote]"
  exit 1
}

do_push() {
  echo "==> Pushing config to ${REMOTE}:${REMOTE_DIR}"
  rsync -avz --delete "${RSYNC_EXCLUDES[@]}" \
    "${REPO_ROOT}/" "${REMOTE}:${REMOTE_DIR}/"
}

case "${1:-}" in
  push)
    do_push
    echo "==> Done. On the remote run: sudo nixos-rebuild switch --flake ${REMOTE_DIR}#laptop"
    ;;
  pull)
    echo "==> Pulling config from ${REMOTE}:${REMOTE_DIR}"
    rsync -avz --delete "${RSYNC_EXCLUDES[@]}" \
      "${REMOTE}:${REMOTE_DIR}/" "${REPO_ROOT}/"
    echo "==> Done."
    ;;
  deploy)
    do_push
    echo "==> Rebuilding and switching on the remote"
    ssh "${REMOTE}" "cd ${REMOTE_DIR} && sudo nixos-rebuild switch --flake .#laptop"
    ;;
  *)
    usage
    ;;
esac
