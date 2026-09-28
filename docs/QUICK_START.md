# 快速上手

## 1. 克隆

```bash
git clone <your-repo> Nixos-Configuration && cd Nixos-Configuration
```

## 2. 选角色

- 仅命令行：`roles/nixos/base.nix` + `roles/home/common.nix`
- 桌面（niri + SHORiN minimal-niri：ly 登录/waybar/fuzzel/mako/hyprlock）：`roles/nixos/desktop.nix` + `roles/home/desktop.nix`（默认 `hosts/laptop` 即此）

在 `hosts/laptop/default.nix` 中已配好：

```nix
imports = [ ./hardware-configuration.nix ../../roles/nixos/desktop.nix ];
hardware.intel.enable = true;
locales.zh-cn.enable = true;
```

换显卡仅改 `hardware.intel.enable -> hardware.nvidia.enable`，换地区加 `locales.ja-jp.enable`。

## 3. 一键安装 (合并版)

```bash
# 改目标盘
$EDITOR hosts/laptop/disko-fs.nix  # device = "/dev/nvme0n1"

# 运行合并安装脚本 (包含 disko + 配置生成 + nixos-install)
chmod +x scripts/install.sh && sudo ./scripts/install.sh
```

> 安装脚本会自动:
> 1. 启用 nix-command 和 flakes
> 2. 运行 disko 分区格式化
> 3. 复制仓库到 /mnt/etc/nixos
> 4. 生成本机配置并移动到 hosts/laptop/
> 5. 提示编辑 ROOT/ESP UUID
> 6. 运行 nixos-install

仅需在脚本提示确认时按 y，需要时编辑 UUID。

## 4. 安装后/日常维护

```bash
cd ~/Nixos-Configuration
git add -A && sudo nixos-rebuild switch --flake .#laptop
```

## 5. 新增主机

```bash
mkdir -p hosts/desktop
cp hosts/laptop/{hardware-configuration.nix,disko-fs.nix,niri-hardware.kdl} hosts/desktop/
# 编辑 hosts/desktop/default.nix，改 hostName + 角色
# flake-parts/hosts.nix 加一行：
# desktop = lib.mkHost inputs { system="x86_64-linux"; hostname="desktop"; hostPath=../hosts/desktop; };
```

## 6. 新增模块

```bash
cp modules/_templates/enable-option.nix modules/nixos/desktop/myfeat.nix
# 在 modules/nixos/desktop/default.nix 加 ./myfeat.nix
# 在 roles/nixos/desktop.nix 或 hosts 中设 my.myfeat.enable = true
```

常见问题见 `docs/FAQ.md`，完整结构见 `docs/STRUCTURE.md`。
