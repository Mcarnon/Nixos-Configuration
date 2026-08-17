# NixOS Configuration

McCarnon 的个人 NixOS 配置，基于 **Flakes**，同时支持 **desktop**、**laptop** 和 **vm** 三台机器，便于在 GitHub 上版本管理和在虚拟机里测试。

## 目录结构

```
.
├── flake.nix            # 入口：输入源 + 每个 host 的 nixosConfiguration
├── hosts/               # 每台机器的专属配置
│   ├── desktop/         #   台式机
│   ├── laptop/          #   笔记本
│   └── vm/              #   虚拟机（测试用，无桌面）
│       ├── default.nix
│       └── hardware-configuration.nix   # 机器硬件配置
├── modules/
│   ├── default.nix      #   共享基础配置（用户 / Nix / 网络 / 时区 / home-manager）
│   └── desktop.nix      #   桌面环境（niri + Noctalia + greetd + PipeWire）
└── home/
    └── default.nix      #   home-manager 用户级配置（软件 + niri/noctalia 配置）
```

设计思路：

- `modules/default.nix` 是所有机器共享的基础配置，用户名在文件顶部的 `let username = ...` 里改。
- `modules/desktop.nix` 是有图形界面的机器（desktop / laptop）共享的桌面环境，`vm` 不引入。
- `hosts/<name>/default.nix` 只放这台机器特有的东西（主机名、引导、硬件固件等）。

## 快速开始

### 1. 克隆仓库

```bash
git clone <your-repo-url> ~/nixos-config
cd ~/nixos-config
```

### 2. 生成硬件配置（每台真实机器都要做一次）

```bash
sudo nixos-generate-config --show-hardware-config
```

把输出覆盖到对应机器的 `hardware-configuration.nix`：

```bash
sudo nixos-generate-config --show-hardware-config > hosts/laptop/hardware-configuration.nix
```

> `laptop` 已按当前笔记本填好；`vm` 内置了 QEMU/KVM 通用配置；`desktop` 还是占位，拿到台式机后生成。

### 3. 重建系统

```bash
sudo nixos-rebuild switch --flake .#laptop
# 或 .#desktop / .#vm
```

### 4. 登录

首次登录用户名是 `mccarnon`，密码是 `changeme`（占位），登录后立刻改：

```bash
passwd
```

用户名、密码在 `modules/default.nix` 里改（`let username` 和 `initialPassword`）。

## 国内镜像加速

默认已接入清华 TUNA 镜像：

- `nixpkgs` 使用清华 channel tarball 源（NixOS 26.05）：
  `https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-26.05/nixexprs.tar.xz`
- `nixConfig.extra-substituters` 指向清华二进制缓存镜像：
  `https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store`

说明：

- `home-manager` / `noctalia` 的 `nixpkgs` 都通过 `follows` 复用了上面的镜像源。
- 想切回官方源，把 `flake.nix` 里的 `nixpkgs.url` 改回 `github:NixOS/nixpkgs/nixos-26.05` 即可。
- 中科大（USTC）、上海交大（SJTU）等也有 `nix-channels` 镜像。
- 首次用带 `nixConfig` 的 flake 会问是否允许 `extra-substituters`，选允许；想免询问在 `~/.config/nix/nix.conf` 加 `accept-flake-config = true`。

## 在虚拟机里测试

```bash
nixos-rebuild build-vm --flake .#vm
./result/bin/run-nixos-vm
```

VM 里已启用 SSH 和 QEMU guest agent，方便从宿主机维护。

## GitHub 维护流程

```bash
git add -A
git commit -m "..."
git push
```

- **`flake.lock` 一定要提交**，保证可复现。
- **不要提交任何密钥**。`.gitignore` 已忽略 `secrets/` 和 `*.age`。

## 添加一台新机器

1. 复制一个现有 host：

   ```bash
   cp -r hosts/vm hosts/server
   ```

2. 修改 `hosts/server/default.nix` 的 `networking.hostName`、引导方式，以及是否引入 `modules/desktop.nix`。

3. 在 `flake.nix` 的 `nixosConfigurations` 加一行：

   ```nix
   server = mkHost "server";
   ```

4. 生成硬件配置并重建：

   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/server/hardware-configuration.nix
   sudo nixos-rebuild switch --flake .#server
   ```

## 下一步（慢慢补）

- 在 `home/default.nix` 配置 shell、编辑器、终端工具等用户级程序。
- 桌面系统级改动在 `modules/desktop.nix`；niri / noctalia 的键位和外观在 `home/default.nix`。
- 台式机硬件配置拿到后补 `hosts/desktop/hardware-configuration.nix`（可能还有 GPU 驱动）。

格式化代码用 `nix fmt`。
