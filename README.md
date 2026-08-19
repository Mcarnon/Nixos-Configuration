# NixOS + Flake + Home Manager — 华为笔记本 (niri + Noctalia)

面向华为笔记本 (Intel CPU + Iris 核显) 的 NixOS 配置，包含：

- **Flake + Home Manager** 声明式管理
- **tmpfs 根分区** + 细粒度 **btrfs 子卷**（`nix` / `var` / `etc` / `home`）
- **niri** 可滚动平铺 Wayland 合成器 + **Noctalia** 桌面外壳
- **Intel Iris Xe** 图形加速（VA-API）
- **中文环境**（locale + 字体 + Fcitx5 输入法）
- **SSH 远程同步 / 部署**到另一台电脑

## 目录结构

```
.
├── flake.nix                    # flake 入口 (inputs + nixosConfigurations)
├── configuration.nix            # 主机主配置 (用户/引导/网络/nix/home-manager 接线)
├── hardware-configuration.nix   # 硬件 + tmpfs 根 + btrfs 子卷挂载
├── chinese.nix                  # 中文 locale / 字体 / Fcitx5 输入法
├── modules/
│   ├── default.nix              # 模块汇总
│   ├── niri.nix                 # niri + greetd 登录
│   ├── audio.nix                # PipeWire
│   ├── intel.nix                # Intel 微码 + Iris Xe
│   ├── laptop.nix               # 电源 / 蓝牙 / fwupd
│   └── ssh.nix                  # SSH 客户端 + 远端主机别名
├── home/
│   ├── default.nix              # 用户环境 (Home Manager)
│   ├── niri.nix                 # 链接 niri 配置目录
│   ├── noctalia.nix             # Noctalia 配置
│   └── niri/                    # niri KDL 配置 (拆分)
│       ├── config.kdl           # 主配置 (include 子文件)
│       ├── binds.kdl            # 快捷键
│       ├── output.kdl           # 输出
│       ├── startup.kdl          # 自启动
│       └── windowrule.kdl       # 窗口/层规则
└── scripts/
    ├── setup-btrfs.sh           # 一次性创建 btrfs 子卷
    └── sync.sh                  # SSH 同步/部署
```

## 磁盘设计（tmpfs + btrfs 子卷）


- 根文件系统 `/` 挂载为 **tmpfs**，重启即清空（“erase your darlings”）。
- 需要持久化的数据用独立的 btrfs 子卷挂载：

| 子卷   | 挂载点  | 内容 |
|--------|---------|------|
| `@nix`  | `/nix`  | Nix store（必须持久） |
| `@var`  | `/var`  | 日志、运行状态 |
| `@etc`  | `/etc`  | `machine-id`、SSH 主机密钥等 |
| `@home` | `/home` | 用户数据 |

`/boot` 是独立的 EFI 系统分区（ESP）。

## 安装

1. 用 NixOS 安装 ISO 启动。
2. 分区：创建 ESP（类型 `EF00`，约 1G）+ 一个 btrfs 分区（其余空间）。
3. 格式化：
   ```bash
   mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1        # ESP
   mkfs.btrfs -f -L nixos /dev/nvme0n1p2        # btrfs
   ```
4. 创建子卷并挂载：
   ```bash
   mount /dev/nvme0n1p2 /mnt
   ./scripts/setup-btrfs.sh /mnt
   umount /mnt

   mount -t tmpfs none /mnt
   mkdir -p /mnt/{boot,nix,var,etc,home}
   mount /dev/nvme0n1p1 /mnt/boot
   mount -o subvol=@nix,compress=zstd,noatime  /dev/nvme0n1p2 /mnt/nix
   mount -o subvol=@var,compress=zstd,noatime  /dev/nvme0n1p2 /mnt/var
   mount -o subvol=@etc,compress=zstd,noatime  /dev/nvme0n1p2 /mnt/etc
   mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p2 /mnt/home
   ```
   > 设备名以 `lsblk` 为准（常见 `/dev/nvme0n1` 或 `/dev/nvme1n1`）。
5. 查 UUID 并填入 `hardware-configuration.nix`：
   ```bash
   blkid
   ```
   把 btrfs 分区的 UUID 填到 `<BTRFS-UUID>`，ESP 的 UUID 填到 `<ESP-UUID>`。
6. 安装：
   ```bash
   sudo nixos-install --flake .#huawei
   ```
7. 重启后通过 greetd 登录进入 niri。

## 首次使用前要改的东西

| 位置 | 内容 |
|------|------|
| `hardware-configuration.nix` | 磁盘 UUID（`blkid` 查看） |
| `configuration.nix` | 用户名 `userName`、`hostName`、`stateVersion` |
| `modules/ssh.nix` | 远端电脑 IP / 用户名 |
| `home/noctalia.nix` | 壁纸路径、主题 |
| `chinese.nix` | 输入法方案（如需 Rime 雾凇拼音） |

## SSH 远程同步 / 部署

配置里定义了 SSH 别名 `nixos-remote`（见 `modules/ssh.nix`），先改成你的远端电脑地址。

```bash
chmod +x scripts/sync.sh

./scripts/sync.sh push    # 把本机配置推到远端
./scripts/sync.sh pull    # 从远端拉取配置
./scripts/sync.sh deploy  # 推送 + 远端 nixos-rebuild 切换
```

也可以直接用 NixOS 内置的远程部署：

```bash
nixos-rebuild switch --flake .#huawei --target-host alice@192.168.1.100
```

## 说明与可选增强

- **Noctalia 二进制缓存**：已在 `flake.nix` / `configuration.nix` 配置 Cachix；`noctalia` 输入锁定 `cachix` 分支，且未对 nixpkgs 设置 `follows`（否则失去缓存）。
- **impermanence**：当前直接用 btrfs 子卷做持久化。若想让 `/etc`、`/home` 也变成 tmpfs、只持久化少量文件，可引入 `nix-community/impermanence`。
- **polkit 认证代理**：niri 本身不带图形 polkit agent，需要 GUI 提权时可自行添加（如 `polkit_gnome`）。
- **XWayland**：默认关闭，需要运行 X11 程序可参考 niri 文档配置 `xwayland-satellite`。
- **锁屏**：Noctalia 自带锁屏，快捷键 `Super+Alt+L`；合盖挂起默认交给 logind。
