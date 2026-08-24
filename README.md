# NixOS + Flake + Home Manager

## Features

- **Flake + Home Manager** declarative management
- **disko** partitioning as code (tmpfs root + fine-grained btrfs subvolumes)
- **hosts/<host>/** machine-specific isolation (hardware / disks / display)
- **niri** scrollable-tiling Wayland compositor + **Noctalia** desktop shell
- **Intel Iris Xe** graphics acceleration (VA-API)
- **Chinese environment** (locale + fonts + Fcitx5 input method)
- **SSH remote sync / deploy** to another machine

## Directory structure

```
.
├── flake.nix                    # flake entry (inputs + nixosConfigurations.laptop)
├── MAINTENANCE.md               # day-to-day maintenance (updates / hardware / config)
├── locales/                     # locale / input method / font framework + region profiles
│   ├── default.nix              # shared framework (primary locale, Fcitx5, base fonts)
│   └── zh-cn.nix                # Chinese (Simplified) environment
├── hosts/
│   └── laptop/                  # machine-specific
│       ├── default.nix          # host identity (user/hostname/timezone/stateVersion) + wiring
│       ├── hardware-configuration.nix  # tmpfs root + btrfs subvolume mounts (real UUIDs on the machine)
│       ├── disko-fs.nix         # partitioning as code (disko)
│       ├── intel.nix            # Intel microcode + Iris Xe
│       └── niri-hardware.kdl    # display / output config
├── modules/                     # reusable, host-agnostic system modules
│   ├── default.nix              # module summary
│   ├── boot.nix                 # systemd-boot + initrd systemd
│   ├── network.nix              # NetworkManager
│   ├── nix.nix                  # nix settings + GC
│   ├── cli.nix                  # base CLI tools
│   ├── diagnostics.nix          # maintenance / diagnostic tools
│   ├── niri.nix                 # niri + greetd login
│   ├── audio.nix                # PipeWire
│   ├── laptop.nix               # power / bluetooth / fwupd
│   └── ssh.nix                  # SSH client + remote host alias
├── home/                        # user environment (Home Manager)
│   ├── default.nix
│   ├── niri.nix                 # links niri config (incl. host's niri-hardware.kdl)
│   ├── noctalia.nix             # Noctalia config
│   └── niri/                    # shared niri KDL config
│       ├── config.kdl           # main config (includes sub-files)
│       ├── binds.kdl            # keybindings
│       ├── startup.kdl          # startup commands
│       └── windowrule.kdl       # window / layer rules
└── scripts/
    └── sync.sh                  # SSH sync / deploy
```

Rule of thumb: if a setting only applies to *this* laptop, put it in
`hosts/laptop/`; if it could apply to any machine, put it in `modules/`.

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

## Disk layout (tmpfs + btrfs subvolumes)

- The root filesystem `/` is mounted as **tmpfs** and is wiped on every reboot ("erase your darlings").
- Data that must persist lives on dedicated btrfs subvolumes:

| subvolume | mountpoint | contents |
|-----------|------------|----------|
| `@nix`  | `/nix`  | Nix store (must persist) |
| `@var`  | `/var`  | logs, runtime state |
| `@etc`  | `/etc`  | machine-id, SSH host keys, etc. |
| `@home` | `/home` | user data |

`/boot` is a separate EFI system partition (ESP).

## SSH remote sync / deploy

An SSH alias `nixos-remote` is defined in `modules/ssh.nix` — change it to your remote machine's address first.

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
   git clone https://github.com/Mcarnon/Nixos-Configuration && cd Nixos-Configuration
   ```
2. Set the target disk in `hosts/laptop/disko-fs.nix`
   (`device = "/dev/nvme0n1"`, or `/dev/disk/by-id/...`).
3. Partition, format, create subvolumes and mount (wipes the target disk):
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
   Replace the placeholders `<BTRFS-UUID>` / `<ESP-UUID>` in
   `/mnt/home/<user>/Nixos-Configuration/hosts/laptop/hardware-configuration.nix`
   with the real btrfs / ESP UUIDs.
6. Flakes ignore untracked files — stage your edits — then install from the
   copy inside the target:
   ```bash
   cd /mnt/home/<user>/Nixos-Configuration
   git add -A
   sudo nixos-install --flake .#laptop
   ```
7. Reboot and log in via greetd into niri. The repo now lives at
   `~/Nixos-Configuration`; see [MAINTENANCE.md](MAINTENANCE.md) for everything
   after that.

Reinstalling later is the same flow — disko's `destroy` step handles the wipe.

## Things to change before first use

| Location | What |
|----------|------|
| `hosts/laptop/disko-fs.nix` | target disk `device` |
| `hosts/laptop/hardware-configuration.nix` | disk UUIDs (auto-filled during install, see above) |
| `hosts/laptop/default.nix` | user name `userName`, `hostName`, `stateVersion` |
| `hosts/laptop/niri-hardware.kdl` | display resolution / scale |
| `modules/ssh.nix` | remote IP / user |
| `home/noctalia.nix` | wallpaper path, theme |
| `locales/zh-cn.nix` | input method (e.g. Rime Wusong Pinyin if desired) |

## Notes & optional enhancements

- **Noctalia binary cache**: configured in `flake.nix` (`nixConfig`) and `modules/nix.nix` via Cachix; the `noctalia` input is pinned to the `cachix` branch and intentionally does **not** set `follows` on nixpkgs (otherwise the cache is lost).
- **impermanence**: this setup persists state directly with btrfs subvolumes. If you want `/etc` and `/home` on tmpfs too, persisting only a few files, add `nix-community/impermanence`.
- **polkit auth agent**: niri ships no graphical polkit agent; add one (e.g. `polkit_gnome`) if you need GUI privilege prompts.
- **XWayland**: off by default; configure `xwayland-satellite` per the niri docs if you need X11 apps.
- **Lock screen**: Noctalia has a built-in lock screen bound to `Super+Alt+L`; lid-close suspend is handled by logind.
