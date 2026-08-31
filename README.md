# NixOS + Flake + Home Manager

## Features

- **flake-parts** standardized entry (perSystem memoization, `nix flake check` parallelism)
- **Flake + Home Manager** declarative management
- **disko** partitioning as code (tmpfs root + fine-grained btrfs subvolumes)
- **LUKS** full-disk encryption (single passphrase, encrypted swap) + hardware HAL (`hardware.intel.enable`)
- **agenix** secrets management (age-encrypted, decrypt only on the target host)
- **roles/** host composition (base/desktop) — cross-host reuse without double-eval
- **niri** scrollable-tiling Wayland compositor + **Clavis**（Quickshell 桌面壳）：ly 登录 + keystone 状态栏 + Spotlight 启动器 + 控制中心 + 锁屏 + Matugen M3 动态主题
- **Intel Iris Xe** graphics acceleration (VA-API) via `modules/hardware/intel.nix`
- **Chinese environment** (locale + fonts + Fcitx5 input method)
- **Miyu** terminal AI assistant via overlay `pkgs.miyu` + `home/modules/miyu.nix`
- **Hardened baseline**: firewall default-closed, SSH keys-only (TODO flip after agenix), zram + BBR + GC/auto-optimise
- **CI**: `nix flake check` (VM test `checks/miyu.nix`) in `.github/workflows/ci.yml`

## 快速开始

> 详细教程见 [docs/QUICK_START.md](docs/QUICK_START.md)，结构说明见 [docs/STRUCTURE.md](docs/STRUCTURE.md)

```bash
git clone <your-repo> Nixos-Configuration && cd Nixos-Configuration
$EDITOR hosts/laptop/disko-fs.nix          # 改 device
sudo nix run github:nix-community/disko/latest -- --mode destroy,format,mount ./hosts/laptop/disko-fs.nix
sudo nixos-generate-config --root /mnt && blkid  # 填 hosts/laptop/hardware-configuration.nix 的 UUID
git add -A && sudo nixos-install --flake .#laptop
# 日常
git add -A && sudo nixos-rebuild switch --flake .#laptop
```

## Directory structure

```
.
├── flake.nix / flake-parts/{hosts,packages,checks}.nix / lib/default.nix / pkgs/ # 入口/装配/覆盖层
├── modules/
│   ├── nixos/
│   │   ├── core/{boot.nix,nix.nix,shell.nix,persist.nix,kernel.nix,cli.nix,diagnostics.nix}
│   │   ├── desktop/{niri.nix,ly.nix,audio.nix}   # niri拆ly(登录), pipewire->audio
│   │   ├── hardware/{intel.nix,nvidia.nix,power.nix,disko.nix}
│   │   ├── network/{manager.nix,openssh.nix,firewall.nix}
│   │   ├── security/{hardening.nix,secrets.nix,sops.nix}
│   │   └── i18n/ -> ../../locales                    # locale框架垫片
│   ├── home/
│   │   ├── shell/{fish.nix,tools.nix} # fish 含 SHORiN 风格函数（y/cat/ls/lt/la/sl/f）
│   │   ├── desktop/{niri.nix,appearance.nix,clavis/}
│   │   ├── apps/{cli,gui,media,network,ai,neovim}.nix
│   │   └── services/{miyu,cliphist}.nix
│   └── _templates/{enable-option.nix,nested-import.nix,example-simple.nix}
├── roles/                       # 主机/用户组合（base/desktop）
│   ├── nixos/{base.nix,desktop.nix}
│   └── home/{common.nix,desktop.nix}
├── hosts/laptop/{default.nix,hardware-configuration.nix,disko-fs.nix,niri-hardware.kdl}
├── locales/{default.nix,zh-cn.nix}                   # locale/输入法/字体框架（canonical）
├── home/{default.nix,files/{miyu.fish,f.fish,fwatch.fish,foot.ini,...},niri/{config,binds,blur,startup,windowrule}.kdl}
├── wallpapers/                                       # 登录界面背景
├── docs/{QUICK_START,STRUCTURE,MIGRATION,DESKTOP,FAQ}.md
├── checks/miyu.nix  .github/workflows/ci.yml  scripts/sync.sh
```

Rule of thumb: `hosts/<host>/` = 身份+硬件+选 `roles/`；`modules/nixos+home` = 按域可复用；`roles/` = 组合。

## Adding a region environment

Locale / input-method / font setup is split into a shared **framework**
(`locales/default.nix`) and one **profile per region** (`locales/zh-cn.nix`).
The framework owns the Fcitx5 input-method framework and the base fonts; each
region only adds its own locale, input engine and font preferences.

To add e.g. Japanese:

1. Create `locales/ja-jp.nix` and declare `options.locales.ja-jp.enable`.
2. Import it in `locales/default.nix`.
3. Enable it in `hosts/laptop/default.nix` (`locales.ja-jp.enable = true;`).

Several regions can be enabled at once; only `locales.defaultLocale` is a
single value.

## Disk layout (tmpfs + LUKS + btrfs subvolumes)

- The root filesystem `/` is mounted as **tmpfs** and is wiped on every reboot ("erase your darlings").
- Everything persistent lives on btrfs subvolumes inside a single **LUKS** container
  (one passphrase at boot; unlocked as `/dev/mapper/cryptroot`):

| subvolume | mountpoint | contents |
|-----------|------------|----------|
| `@nix`  | `/nix`  | Nix store (must persist) |
| `@var`  | `/var`  | logs, runtime state |
| `@etc`  | `/etc`  | machine-id, SSH host keys, etc. |
| `@home` | `/home` | user data |
| `@swap` | `/swap` | swapfile (encrypted, used for hibernation) |

`/boot` is a separate EFI system partition (ESP), kept unencrypted so UEFI/GRUB
can load the kernel.

## SSH remote sync / deploy

An SSH alias `nixos-remote` is defined in `modules/services/openssh.nix` — change it to your remote machine's address first.

```bash
chmod +x scripts/sync.sh

./scripts/sync.sh push    # push this machine's config to the remote
./scripts/sync.sh pull    # pull config from the remote
./scripts/sync.sh deploy  # push + remote nixos-rebuild switch
```

Or use NixOS's built-in remote deployment:

```bash
nixos-rebuild switch --flake .#laptop --target-host alice@192.168.1.100
```

## Installation

disko does partitioning + formatting + subvolume creation + mounting in one
step. Its `destroy` stage wipes partition-table and filesystem *signatures*
before re-formatting, so **no manual `wipefs -a` is needed**. (If you do want
to erase the disk completely first, e.g. for an SSD reinstall:
`sudo blkdiscard /dev/nvme0n1`.)

1. Boot the NixOS installation ISO, connect to the network, and get this repo
   onto the machine (it lives on the ISO's RAM for now — that's fine):
   ```bash
   git clone <your-repo-url> Nixos-Configuration && cd Nixos-Configuration
   ```
2. Set the target disk in `hosts/laptop/disko-fs.nix`
   (`device = "/dev/nvme0n1"`, or `/dev/disk/by-id/...`).
3. Partition, format, create subvolumes and mount (wipes the target disk; you'll
   be prompted to set the **LUKS passphrase** — remember it, it unlocks the disk
   at every boot):
   ```bash
   sudo nix run github:nix-community/disko/latest -- \
     --mode destroy,format,mount ./hosts/laptop/disko-fs.nix
   ```
   > If `nix-command` / `flakes` are not enabled on the ISO, run
   > `export NIX_CONFIG="experimental-features = nix-command flakes"` first.
4. Copy the repo into the target so it survives on the `@home` subvolume (root
   is tmpfs and wiped on every reboot):
   ```bash
   sudo mkdir -p /mnt/home/<user>
   sudo cp -r Nixos-Configuration /mnt/home/<user>/
   ```
5. Generate a hardware config with the real disk UUIDs:
   ```bash
   sudo nixos-generate-config --root /mnt
   blkid
   ```
   Replace the placeholders `<LUKS-UUID>` / `<ESP-UUID>` in
   `/mnt/home/<user>/Nixos-Configuration/hosts/laptop/hardware-configuration.nix`
   with the real LUKS / ESP UUIDs. (The btrfs subvolumes already reference the
   unlocked mapper `/dev/mapper/cryptroot`, so no btrfs UUID is needed.)
6. (Optional) If you want hibernation, measure the swapfile resume offset and
   fill it in `hardware-configuration.nix` (see the comment at the bottom of
   that file).
7. Flakes ignore untracked files — stage your edits — then install from the
   copy inside the target:
   ```bash
   cd /mnt/home/<user>/Nixos-Configuration
   git add -A
   sudo nixos-install --flake .#laptop
   ```
8. Reboot and log in via **ly** into niri (enter the LUKS passphrase at boot).
   The repo now lives at `~/Nixos-Configuration`; see
   [MAINTENANCE.md](MAINTENANCE.md) for everything after that.

Reinstalling later is the same flow — disko's `destroy` step handles the wipe.

## Things to change before first use

| Location | What |
|----------|------|
| `hosts/laptop/disko-fs.nix` | target disk `device` |
| `hosts/laptop/hardware-configuration.nix` | LUKS / ESP UUIDs + swapfile resume offset |
| `hosts/laptop/default.nix` | `userName`/`hostName`/`stateVersion` + `hardware.intel.enable` + `roles/nixos/desktop` vs `base` |
| `hosts/laptop/niri-hardware.kdl` | display resolution / scale |
| `modules/nixos/network/openssh.nix` | remote IP / user |
| `modules/nixos/network/firewall.nix` | `allowedTCPPorts` (default only 22) |
| `modules/nixos/security/hardening.nix` | `boot.kernel.sysctl` BBR/fq, `zramSwap` |
| `modules/home/desktop/clavis/default.nix` | Clavis 桌面壳（key 启动器 + keytop + systemd 用户服务 + 默认壁纸） |
| `modules/nixos/desktop/ly.nix` | 登录界面（ly，TUI 显示管理器） |
| `modules/home/services/miyu.nix` | Miyu TUI (`miyu config`); no prefill needed |
| `locales/zh-cn.nix` | input method (e.g. Rime) |

## Notes & optional enhancements

- **impermanence**: btrfs 子卷直接持久化，需更激进可用 `nix-community/impermanence`。
- **polkit auth agent**: `polkit_gnome` 在 `modules/nixos/desktop/niri.nix` 以 `graphical-session` 服务运行。
- **Miyu**: `pkgs.miyu` overlay + `modules/home/services/miyu.nix` 的 `fish/conf.d/zz-miyu.fish` + `home.activation.miyuInit`；`miyu config` 配置。
- **Performance**: `flake-parts` perSystem 缓存，`nix.gc` weekly，`zramSwap` zstd，`BBR/fq`，`services.resolved` 缓存。
- **Security**: `agenix` `/run/agenix.d` tmpfs，`LUKS`，`networking.firewall` 默认关，`PermitRootLogin no`。
- **XWayland**: off by default; configure `xwayland-satellite` per the niri docs if you need X11 apps.
- **Lock screen**: Clavis 锁屏 bound to `Super+Alt+L`；suspend combo `Mod+Alt+P` 先锁后挂。
- **Wallpaper**: 图片丢进 `~/Pictures/Wallpapers/`，`Mod+F10` 随机切换（`key ipc call wallpaper random`，awww 引擎）。
- **键位教程**: `Mod+Shift+Slash`（niri 内置 hotkey-overlay）。
