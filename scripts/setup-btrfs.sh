#!/usr/bin/env bash
# 一次性脚本: 在 btrfs 分区上创建持久化子卷 (@nix @var @etc @home)
#
# 用法 (在 NixOS 安装 ISO 里, 分区并格式化 btrfs 之后):
#   1. 挂载 btrfs 分区:
#        mount /dev/<disk>p2 /mnt
#   2. 运行:
#        ./scripts/setup-btrfs.sh /mnt
set -euo pipefail

MNT="${1:-/mnt}"

if ! mountpoint -q "${MNT}"; then
  echo "错误: ${MNT} 不是挂载点, 请先挂载 btrfs 分区到 ${MNT}" >&2
  exit 1
fi

for sub in nix var etc home; do
  path="${MNT}/@${sub}"
  if [ -e "${path}" ]; then
    echo "跳过已存在: ${path}"
  else
    btrfs subvolume create "${path}"
  fi
done

echo "完成。已创建子卷: @nix @var @etc @home"
