#!/usr/bin/env bash
#==============================================================================
# NixOS Installation Script (合并 disko + 配置生成 + nixos-install)
#
# 使用方式:
#   1. 克隆仓库后进入目录:
#      git clone <repo-url> Nixos-Configuration && cd Nixos-Configuration
#
#   2. 修改 hosts/laptop/disko-fs.nix 中的 device 为目标磁盘
#
#   3. 运行本脚本:
#      chmod +x scripts/install.sh && sudo ./scripts/install.sh
#
# 流程:
#   - 启用 nix-command 和 flakes (live 环境可能没有)
#   - 运行 disko 分区格式化
#   - 复制仓库到 /mnt/etc/nixos (持久化配置)
#   - 生成硬件配置并移动到 hosts/laptop/
#   - 运行 nixos-install
#==============================================================================

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local yn
    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n] " yn
        [[ "${yn:-Y}" =~ ^[Yy]$ ]]
    else
        read -p "$prompt [y/N] " yn
        [[ "${yn:-N}" =~ ^[Yy]$ ]]
    fi
}

# 检查是否为 root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "请使用 sudo 运行此脚本"
        exit 1
    fi
}

# 检查 nix-command 和 flakes
check_nix_features() {
    info "检查 Nix 实验功能..."
    if ! nix --version &>/dev/null; then
        error "Nix 未安装"
        exit 1
    fi

    # 导出实验功能配置
    export NIX_CONFIG="experimental-features = nix-command flakes"
    info "已启用 nix-command 和 flakes"
}

# 检查磁盘设备
check_disk_device() {
    local disko_file="$1"
    info "检查 disko 配置文件: $disko_file"

    if [[ ! -f "$disko_file" ]]; then
        error "Disko 配置文件不存在: $disko_file"
        exit 1
    fi

    # 检查是否还是默认的 /dev/nvme0n1
    if grep -q 'device = "/dev/nvme0n1"' "$disko_file" 2>/dev/null; then
        warn "检测到默认磁盘设备 /dev/nvme0n1"
        echo ""
        echo "当前 disko-fs.nix 中的设备是默认的 /dev/nvme0n1"
        if confirm "是否继续使用此设备? 这将销毁该磁盘上的所有数据!" "n"; then
            info "继续使用 /dev/nvme0n1"
        else
            error "请先修改 hosts/laptop/disko-fs.nix 中的 device 为你的目标磁盘"
            info "可以使用 lsblk 或 blkid 查看可用设备"
            exit 1
        fi
    else
        # 提取实际设备
        local device
        device=$(grep -o 'device = "[^"]*"' "$disko_file" | head -1 | cut -d'"' -f2)
        if [[ -n "$device" ]]; then
            info "将使用磁盘: $device"
            if ! confirm "确认使用磁盘 $device (所有数据将被销毁)?" "n"; then
                error "安装已取消"
                exit 0
            fi
        fi
    fi
}

# 运行 disko
run_disko() {
    local disko_file="$1"
    info "运行 disko 分区格式化..."
    info "提示: 你需要设置 LUKS 加密密码，请牢记!"

    if ! confirm "即将在目标磁盘上创建分区和加密容器，是否继续?" "n"; then
        error "安装已取消"
        exit 0
    fi

    # 使用 NIX_CONFIG 运行 disko
    NIX_CONFIG="experimental-features = nix-command flakes" \
        nix run github:nix-community/disko/latest -- \
        --mode destroy,format,mount "$disko_file"

    success "Disko 分区完成"
}

# 复制仓库到 /mnt/etc/nixos
copy_repo_to_mnt() {
    local repo_path
    repo_path="$(cd "$(dirname "$0")/.." && pwd)"
    local mnt_etc_nixos="/mnt/etc/nixos"

    info "复制仓库到 $mnt_etc_nixos..."

    # 检查 /mnt 是否已挂载
    if ! mountpoint -q /mnt; then
        error "/mnt 未挂载，disko 可能未成功"
        exit 1
    fi

    # 创建目录并复制
    mkdir -p "$mnt_etc_nixos"
    cp -r "$repo_path" "$mnt_etc_nixos/"

    success "仓库已复制到 $mnt_etc_nixos"
}

# 生成本机配置
generate_hardware_config() {
    local mnt_etc_nixos="/mnt/etc/nixos"
    local repo_name
    repo_name="$(basename "$(cd "$(dirname "$0")/.." && pwd)")"

    info "生成本机硬件配置..."

    # 在 /mnt/etc/nixos 目录下运行 nixos-generate-config
    cd "$mnt_etc_nixos/$repo_name"

    # 确保 flake 可用
    NIX_CONFIG="experimental-features = nix-command flakes" \
        nixos-generate-config --root /mnt

    success "硬件配置已生成"
}

# 处理配置文件
process_configs() {
    local mnt_etc_nixos="/mnt/etc/nixos"
    local repo_name
    repo_name="$(basename "$(cd "$(dirname "$0")/.." && pwd)")"
    local mnt_repo="$mnt_etc_nixos/$repo_name"
    local hosts_dir="$mnt_repo/hosts/laptop"

    info "处理配置文件..."

    # 检查生成的 configuration.nix 是否存在
    if [[ ! -f "$mnt_etc_nixos/configuration.nix" ]]; then
        error "未找到 $mnt_etc_nixos/configuration.nix"
        exit 1
    fi

    # 删除 configuration.nix
    rm -f "$mnt_etc_nixos/configuration.nix"
    info "已删除 $mnt_etc_nixos/configuration.nix"

    # 移动 hardware-configuration.nix 到 hosts/laptop/
    if [[ -f "$mnt_etc_nixos/hardware-configuration.nix" ]]; then
        mv "$mnt_etc_nixos/hardware-configuration.nix" "$hosts_dir/"
        info "已将 hardware-configuration.nix 移动到 $hosts_dir/"
    else
        error "未找到 $mnt_etc_nixos/hardware-configuration.nix"
        exit 1
    fi
}

# 显示 UUID 信息并等待用户编辑
prompt_uuid_edit() {
    local hosts_dir="$1"

    info "显示当前硬件配置中的 UUID 占位符:"
    echo ""
    grep -n "by-uuid" "$hosts_dir/hardware-configuration.nix" || true
    echo ""

    if confirm "是否需要编辑 hardware-configuration.nix 中的 UUID (使用 blkid 查看)?" "n"; then
        local editor="${EDITOR:-nano}"
        $editor "$hosts_dir/hardware-configuration.nix"
    fi
}

# 运行 nixos-install
run_nixos_install() {
    local mnt_etc_nixos="/mnt/etc/nixos"
    local repo_name
    repo_name="$(basename "$(cd "$(dirname "$0")/.." && pwd)")"
    local mnt_repo="$mnt_etc_nixos/$repo_name"

    info "返回 $mnt_repo 目录准备安装..."

    cd "$mnt_repo"

    # 询问用户是否需要设置 root 密码
    echo ""
    if confirm "是否设置 root 密码 (跳过则使用随机密码)?" "n"; then
        passwd
    fi

    # 询问用户名和密码
    local userName
    local userPassword
    read -p "请输入要创建的用户名 [默认: mccarnon]: " userName
    userName="${userName:-mccarnon}"
    read -sp "请输入用户 $userName 的密码: " userPassword
    echo ""

    info "运行 nixos-install..."

    # 设置用户密码
    export NIX_CONFIG="experimental-features = nix-command flakes"

    # 创建用户 (如果还没有)
    if ! id "$userName" &>/dev/null; then
        nixos-enter --home-dir /home/$userName -u "$userName" --command "echo '$userPassword' | passwd $userName" 2>/dev/null || true
    fi

    # 运行安装
    nixos-install --flake .#laptop --no-root-password

    success "NixOS 安装完成!"
    echo ""
    info "下一步:"
    echo "  1. 重启系统: sudo reboot"
    echo "  2. 启动后进入 ~/Nixos-Configuration 目录"
    echo "  3. 运行日常维护: git add -A && sudo nixos-rebuild switch --flake .#laptop"
}

#==============================================================================
# 主流程
#==============================================================================
main() {
    echo ""
    echo "============================================"
    echo "     NixOS Installation Script"
    echo "     合并 disko + 配置生成 + nixos-install"
    echo "============================================"
    echo ""

    check_root
    check_nix_features

    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    local repo_root="$(cd "$script_dir/.." && pwd)"
    local disko_file="$repo_root/hosts/laptop/disko-fs.nix"
    local mnt_etc_nixos="/mnt/etc/nixos"

    # 检查 disko 文件
    check_disk_device "$disko_file"

    # 运行 disko
    run_disko "$disko_file"

    # 复制仓库
    copy_repo_to_mnt

    # 检查是否已有 hardware-configuration.nix
    local hosts_dir="$mnt_etc_nixos/$(basename "$repo_root")/hosts/laptop"
    if [[ -f "$hosts_dir/hardware-configuration.nix" ]] && \
       ! grep -q "<LUKS-UUID>" "$hosts_dir/hardware-configuration.nix" 2>/dev/null; then
        warn "发现已配置的 hardware-configuration.nix，跳过生成步骤"
    else
        # 生成本机配置
        generate_hardware_config

        # 处理配置文件
        process_configs

        # 提示编辑 UUID
        prompt_uuid_edit "$hosts_dir"
    fi

    # 返回 /mnt/etc/nixos 目录并运行安装
    run_nixos-install
}

main "$@"
