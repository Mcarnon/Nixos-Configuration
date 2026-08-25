# NixOS + Flake + Home Manager

## Features

- **flake-parts** standardized entry (perSystem memoization, `nix flake check` parallelism)
- **Flake + Home Manager** declarative management
- **disko** partitioning as code (tmpfs root + fine-grained btrfs subvolumes)
- **LUKS** full-disk encryption (single passphrase, encrypted swap) + hardware HAL (`hardware.intel.enable`)
- **agenix** secrets management (age-encrypted, decrypt only on the target host)
- **profiles/** host composition (base/desktop) — cross-host reuse without double-eval
- **niri** scrollable-tiling Wayland compositor + **Noctalia** desktop shell
- **Intel Iris Xe** graphics acceleration (VA-API) via `modules/hardware/intel.nix`
- **Chinese environment** (locale + fonts + Fcitx5 input method)
- **Miyu** terminal AI assistant via overlay `pkgs.miyu` + `home/modules/miyu.nix`
- **Hardened baseline**: firewall default-closed, SSH keys-only (TODO flip after agenix), zram + BBR + GC/auto-optimise
- **CI**: `nix flake check` (VM test `checks/miyu.nix`) in `.github/workflows/ci.yml`

## Directory structure

```
.
├── flake.nix                    # pure entry: inputs + imports = [ flake-parts/* ]
├── flake-parts/                 # standardized per flake-parts
│   ├── hosts.nix                # nixosConfigurations via lib.mkHost
│   ├── packages.nix             # perSystem.packages.miyu + formatter
│   └── checks.nix               # perSystem.checks (wires ./checks/*)
├── lib/                         # shared helpers (mkHost, hardware helpers)
│   └── default.nix
├── pkgs/                        # custom packages + overlay (single audit surface)
│   ├── default.nix              # overlays.default = { miyu = ...; }
│   └── miyu/                    # Miyu (prebuilt Arch release → Nix, autoPatchelf)
├── profiles/                    # host composition (scale: add a host = compose)
│   ├── base.nix                 # boot/network/nix/packages/shell/snapshot/secrets/security/ssh
│   └── desktop.nix              # base + niri/audio/laptop (Wayland-only)
├── hosts/
│   └── laptop/                  # machine-specific (identity + hardware + profile selection)
│       ├── default.nix          # hostName/timeZone/stateVersion + hardware.intel.enable + imports profiles/desktop + locales
│       ├── hardware-configuration.nix  # LUKS unlock + tmpfs root + btrfs mounts (real UUIDs)
│       ├── disko-fs.nix         # partitioning as code (disko, LUKS + subvolumes + swapfile)
│       └── niri-hardware.kdl    # display / output config
├── modules/                     # reusable, host-agnostic system modules (by domain)
│   ├── default.nix              # compat shim → re-exports services/hardware/security/system
│   ├── system/                  # 系统底层
│   │   ├── boot.nix             # GRUB (EFI) + initrd systemd
│   │   ├── kernel.nix           # kernel knobs (BBR 等在 security/hardening)
│   │   ├── nix.nix              # nix settings (trusted-users, GC, auto-optimise, keep-*)
│   │   ├── shell.nix            # fish (system-wide)
│   │   ├── snapshot.nix         # snapper btrfs snapshots
│   │   └── locales.nix          # re-export top-level locales/
│   ├── services/                # 各类服务
│   │   ├── network.nix          # NetworkManager + resolved cache (firewall 在 security/firewall)
│   │   ├── openssh.nix          # SSH client alias + hardened sshd
│   │   ├── niri.nix             # niri + greetd login + polkit agent
│   │   ├── pipewire.nix         # PipeWire (原 audio.nix)
│   │   └── laptop.nix           # power / bluetooth / fwupd / logind
│   ├── hardware/                # 硬件相关
│   │   ├── intel.nix            # `hardware.intel.enable` HAL (microcode + Iris Xe)
│   │   ├── nvidia.nix           # `hardware.nvidia.enable` HAL (stub for next host)
│   │   └── disko.nix            # disko 模板占位（具体布局在 hosts/*/disko-fs.nix）
│   ├── security/                # 安全
│   │   ├── secrets.nix          # agenix (age identity + usage)
│   │   ├── hardening.nix        # sudo/kernel sysctl (BBR/fq, swappiness) + zram
│   │   ├── firewall.nix         # firewall default-closed (only 22)
│   │   └── sops.nix             # sops 占位（agenix 为主）
│   └── packages/                # 系统软件（按类别分组）
│       ├── default.nix
│       ├── cli.nix
│       └── diagnostics.nix
├── locales/                     # locale / input method / font framework + region profiles
│   ├── default.nix              # shared framework (primary locale, Fcitx5, base fonts)
│   └── zh-cn.nix
├── home/                        # user environment (Home Manager)
│   ├── default.nix              # thin entry → profiles/desktop
│   ├── profiles/
│   │   ├── common.nix           # git + shell + packages (cross-host reuse)
│   │   └── desktop.nix          # common + niri/noctalia/miyu
│   ├── modules/
│   │   └── miyu.nix             # miyu (pkgs.miyu + fish hook + activation + docs)
│   ├── files/
│   │   └── miyu.fish            # miyu fish integration (upstream `miyu fish-init` verbatim)
│   ├── shell.nix                # fish + starship + direnv + fzf + eza + zoxide (pure)
│   ├── niri.nix / noctalia.nix
│   ├── packages/                # user software, grouped by category
│   │   ├── default.nix
│   │   ├── ai.nix               # opencode/aichat/tgpt (miyu lives in home/modules/miyu.nix)
│   │   ├── cli.nix / gui.nix / media.nix / network.nix
│   └── niri/{config,binds,startup,windowrule}.kdl
├── checks/
│   └── miyu.nix                 # NixOS VM test (binary + fish hook smoke)
├── .github/workflows/ci.yml     # nix flake check + fmt --check
├── MAINTENANCE.md
└── scripts/sync.sh
```

Rule of thumb: `hosts/<host>/` = only identity + hardware + profile choice; `modules/` = reusable per-domain; `profiles/` = composition; `home/profiles/` = user env reuse.

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
8. Reboot and log in via greetd into niri (enter the LUKS passphrase at boot).
   The repo now lives at `~/Nixos-Configuration`; see
   [MAINTENANCE.md](MAINTENANCE.md) for everything after that.

Reinstalling later is the same flow — disko's `destroy` step handles the wipe.

## Things to change before first use

| Location | What |
|----------|------|
| `hosts/laptop/disko-fs.nix` | target disk `device` |
| `hosts/laptop/hardware-configuration.nix` | LUKS / ESP UUIDs + swapfile resume offset (auto-filled during install, see above) |
| `hosts/laptop/default.nix` | `userName`/`hostName`/`stateVersion` + `hardware.intel.enable` (HAL) + profile choice (`profiles/desktop` vs `base`) |
| `hosts/laptop/niri-hardware.kdl` | display resolution / scale |
| `modules/services/openssh.nix` | remote IP / user |
| `modules/security/firewall.nix` | `allowedTCPPorts` (default only 22) |
| `modules/security/hardening.nix` | `boot.kernel.sysctl` BBR/fq, `zramSwap` — tune or disable per host |
| `home/noctalia.nix` | wallpaper path, theme |
| `home/modules/miyu.nix` | Miyu model/provider is TUI (`miyu config`); no prefill needed |
| `locales/zh-cn.nix` | input method (e.g. Rime Wusong Pinyin if desired) |

## Notes & optional enhancements

- **Noctalia binary cache**: configured in `flake.nix` (`nixConfig`) and `modules/system/nix.nix` via Cachix; the `noctalia` input is pinned to the `cachix` branch and intentionally does **not** set `follows` on nixpkgs (otherwise the cache is lost).
- **impermanence**: this setup persists state directly with btrfs subvolumes. If you want `/etc` and `/home` on tmpfs too, persisting only a few files, add `nix-community/impermanence`.
- **polkit auth agent**: `polkit_gnome` runs as a graphical-session service (in `modules/services/niri.nix`) so GUI privilege prompts work.
- **Miyu AI assistant**: binary via overlay `pkgs.miyu` (`pkgs/miyu` prebuilt Arch release, autoPatchelf), fish hook via `home/files/miyu.fish` → `xdg.configFile fish/conf.d/zz-miyu.fish` in `home/modules/miyu.nix` (loads after starship), auto-init via `home.activation.miyuInit`. Configure: `miyu config` / `miyu models` / `miyu paths`. See `home/modules/miyu.nix` header.
- **Performance**: `flake-parts` perSystem memoization, `nix.settings.max-jobs/cores`, `nix.gc` weekly + `--delete-older-than 7d`, `auto-optimise-store`, `zramSwap` (zstd), `net.ipv4.tcp_congestion_control=bbr` + `fq`, `services.resolved` cache. Binary caches in `flake.nix:nixConfig` + `modules/system/nix.nix`.
- **Security**: `age` via `agenix` (`/run/agenix.d`, tmpfs), `LUKS` (`allowDiscards` = TRIM, comment out for stricter), `networking.firewall` default-closed (only 22), `services.openssh` `PermitRootLogin no` + flip `PasswordAuthentication` to `false` after agenix, `security.sudo.execWheelOnly`, `boot.kernel.sysctl` (`kptr_restrict`, `ptrace_scope`), `nix.settings.trusted-users = [ root @wheel ]`, `nix.channel.enable = false`.
- **XWayland**: off by default; configure `xwayland-satellite` per the niri docs if you need X11 apps.
- **Lock screen**: Noctalia has a built-in lock screen bound to `Super+Alt+L`; lid-close suspend is handled by logind.
