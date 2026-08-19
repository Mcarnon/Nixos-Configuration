#!/usr/bin/env bash
# 通过 SSH + rsync 在另一台电脑之间同步 / 部署本 NixOS 配置
#
# 用法:
#   ./scripts/sync.sh push   [remote]   # 把本机配置推到远端
#   ./scripts/sync.sh pull   [remote]   # 从远端拉取配置到本机
#   ./scripts/sync.sh deploy [remote]   # 推送 + 远端 nixos-rebuild 切换
#
# remote 默认是 SSH 别名 nixos-remote (见 modules/ssh.nix)

set -euo pipefail

REMOTE="${2:-nixos-remote}"
# 远端存放配置的目录 (支持 ~ 展开)
REMOTE_DIR="${REMOTE_DIR:-~/nixos}"

# 仓库根目录 (scripts/ 的上一级)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RSYNC_EXCLUDES=(
  --exclude '.git'
  --exclude 'result'
  --exclude 'result-*'
  --exclude '.direnv'
)

usage() {
  echo "用法: $0 {push|pull|deploy} [remote]"
  exit 1
}

do_push() {
  echo "==> 推送配置到 ${REMOTE}:${REMOTE_DIR}"
  rsync -avz --delete "${RSYNC_EXCLUDES[@]}" \
    "${REPO_ROOT}/" "${REMOTE}:${REMOTE_DIR}/"
}

case "${1:-}" in
  push)
    do_push
    echo "==> 完成。可在远端执行: sudo nixos-rebuild switch --flake ${REMOTE_DIR}#huawei"
    ;;
  pull)
    echo "==> 从 ${REMOTE}:${REMOTE_DIR} 拉取配置"
    rsync -avz --delete "${RSYNC_EXCLUDES[@]}" \
      "${REMOTE}:${REMOTE_DIR}/" "${REPO_ROOT}/"
    echo "==> 完成。"
    ;;
  deploy)
    do_push
    echo "==> 远端重建并切换配置"
    ssh "${REMOTE}" "cd ${REMOTE_DIR} && sudo nixos-rebuild switch --flake .#huawei"
    ;;
  *)
    usage
    ;;
esac
