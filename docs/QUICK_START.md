# 快速上手

## 1. 克隆

```bash
git clone <your-repo> Nixos-Configuration && cd Nixos-Configuration
```

## 2. 选角色

- 仅命令行：`roles/nixos/base.nix` + `roles/home/common.nix`
- 桌面（niri+Noctalia）：`roles/nixos/desktop.nix` + `roles/home/desktop.nix`（默认 `hosts/laptop` 即此）

在 `hosts/laptop/default.nix` 中已配好：

```nix
imports = [ ./hardware-configuration.nix ../../roles/nixos/desktop.nix ];
hardware.intel.enable = true;
locales.zh-cn.enable = true;
```

换显卡仅改 `hardware.intel.enable -> hardware.nvidia.enable`，换地区加 `locales.ja-jp.enable`。

## 3. 磁盘与硬件

```bash
# 改目标盘
$EDITOR hosts/laptop/disko-fs.nix  # device = "/dev/nvme0n1"

# 分区+格式化+挂载（会清盘，输 LUKS 口令）
sudo nix run github:nix-community/disko/latest -- --mode destroy,format,mount ./hosts/laptop/disko-fs.nix

sudo mkdir -p /mnt/home/mccarnon && sudo cp -r . /mnt/home/mccarnon/Nixos-Configuration
sudo nixos-generate-config --root /mnt
# 用 blkid 的真实 UUID 替换 hosts/laptop/hardware-configuration.nix 的 <LUKS-UUID>/<ESP-UUID>
```

## 4. 安装/切换

```bash
git add -A
sudo nixos-install --flake .#laptop   # 首次
# 日常
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
