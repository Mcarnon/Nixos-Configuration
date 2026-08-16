# NixOS Configuration

McCarnon 的个人 NixOS 配置，基于 **Flakes** 的模块化结构，同时支持 **desktop**、**laptop** 和 **vm** 三台机器，便于在 GitHub 上版本管理和在虚拟机里测试。

## 目录结构

```
.
├── flake.nix            # 入口：输入源 + 每个 host 的 nixosConfiguration
├── hosts/               # 每台机器的专属配置
│   ├── desktop/         #   台式机
│   ├── laptop/          #   笔记本
│   └── vm/              #   虚拟机（测试用）
│       ├── default.nix
│       └── hardware-configuration.nix   # 机器硬件配置
├── modules/             # 所有机器共享的模块
│   ├── default.nix      #   共享基础配置（汇总下面这些）
│   ├── options.nix      #   自定义选项（my.role / my.username / ...）
│   ├── locale.nix       #   语言 / 时区
│   ├── nix.nix          #   Nix 自身配置
│   ├── network.nix      #   网络（NetworkManager）
│   ├── security.nix     #   安全相关
│   ├── users.nix        #   用户
│   └── home-manager.nix #   home-manager 接入
└── home/                # home-manager 用户级配置
    └── default.nix
```

设计思路：

- `hosts/<name>/default.nix` 只放 **这台机器特有的东西**（主机名、引导、角色、桌面环境等）。
- `modules/` 放 **所有机器共享的东西**（用户、网络、Nix 配置等）。
- `my.*` 是一组自定义选项（角色、用户名、时区……），机器在 `default.nix` 里覆盖，共享模块通过 `config.my.*` 读取。

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

把输出内容覆盖到对应机器的 `hardware-configuration.nix`：

```bash
sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix
```

> `vm/hardware-configuration.nix` 已经内置了 QEMU/KVM 的通用配置，通常不用改。

### 3. 重建系统

在 `flake.nix` 同目录下执行：

```bash
# 先跑一次 `nix flake lock`（或首次构建时会自动生成）
sudo nixos-rebuild switch --flake .#desktop
# 或 laptop / vm
sudo nixos-rebuild switch --flake .#laptop
```

### 4. 登录

首次登录的用户名是 `mccarnon`，密码是 `changeme`（占位），登录后请立刻改：

```bash
passwd
```

用户名、密码等在 `modules/users.nix` 和 `modules/options.nix` 中修改。

## 国内镜像加速

默认已接入清华 TUNA 镜像，避免直接从 GitHub / cache.nixos.org 下载太慢：

- `nixpkgs` 输入使用清华的 channel tarball 源：
  `https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz`
- `nixConfig.extra-substituters` 指向清华的二进制缓存镜像：
  `https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store`

说明：

- `home-manager` 仓库本身很小，仍从 GitHub 拉取；它的 `nixpkgs` 通过 `follows` 复用了上面的镜像源。
- 想切回官方源，把 `flake.nix` 里的 `nixpkgs.url` 改回 `github:NixOS/nixpkgs/nixos-unstable` 即可。
- 中科大（USTC）、上海交大（SJTU）等也有 `nix-channels` 镜像，可自行替换域名。
- 首次使用带 `nixConfig` 的 flake 时，Nix 会问 `do you want to allow configuration setting 'extra-substituters'?`，选允许即可；想免去询问可在 `~/.config/nix/nix.conf` 里加 `accept-flake-config = true`。

## 在虚拟机里测试

推荐用 QEMU/KVM 跑 `vm` 这个 host，验证改动后再推到真实机器。

1. 构建一个虚拟机磁盘镜像：

   ```bash
   nix build .#nixosConfigurations.vm.config.system.build.vm
   ```

2. 用一个方便的方式启动（这里以 `quickemu`/`virt-manager` 为例），或者直接给 `nixos-rebuild` 用 `build-vm`：

   ```bash
   nixos-rebuild build-vm --flake .#vm
   ./result/bin/run-nixos-vm
   ```

3. VM 里已经启用了 SSH 和 QEMU guest agent，方便从宿主机维护。

## GitHub 维护流程

```bash
git add -A
git commit -m "..." 
git push
```

- **`flake.lock` 一定要提交**，这样每台机器、每次构建用的都是同一套依赖版本，保证可复现。
- **不要提交任何密钥**。`.gitignore` 已经忽略了 `secrets/` 和 `*.age`；以后如果用到 agenix / sops，把密文单独管理。

## 添加一台新机器

1. 复制一个现有 host：

   ```bash
   cp -r hosts/vm hosts/server
   ```

2. 修改 `hosts/server/default.nix` 里的 `my.role` / `my.hostName` 和引导方式。

3. 在 `flake.nix` 的 `nixosConfigurations` 里加一行：

   ```nix
   server = mkHost "server";
   ```

4. 生成硬件配置并重建：

   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/server/hardware-configuration.nix
   sudo nixos-rebuild switch --flake .#server
   ```

## 下一步（慢慢补）

- 在 `hosts/*/default.nix` 里启用桌面环境（GNOME / KDE / Hyprland …）。
- 在 `home/default.nix` 里配置 shell、编辑器、终端工具等用户级程序。
- 需要时新增 `modules/desktop/`、`modules/programs/` 等子模块，保持模块化。

格式化代码用 `nix fmt`。
