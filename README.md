# NixOS + Flake + Home Manager

## Features

- **Flake + Home Manager** declarative management
- **disko** partitioning as code (tmpfs root + fine-grained btrfs subvolumes)
- **hosts/<host>/** machine-specific isolation (hardware / disks / display)
- **niri** scrollable-tiling Wayland compositor + **Noctalia** desktop shell
- **Intel Iris Xe** graphics acceleration (VA-API)
- **Chinese environment** (locale + fonts + Fcitx5 input method)

## Directory structure

```
.
├── flake.nix                    # flake entry (inputs + nixosConfigurations.laptop)
├── chinese.nix                  # Chinese locale / fonts / Fcitx5 input method (shared)
├── hosts/
│   └── laptop/                  # machine-specific
│       ├── default.nix          # host main config (user/boot/network/nix/home-manager wiring)
│       ├── hardware-configuration.nix  # tmpfs root + btrfs subvolume mounts
│       ├── disko-fs.nix         # partitioning as code (disko)
│       ├── intel.nix            # Intel microcode + Iris Xe
│       └── niri-hardware.kdl    # display / output config
├── modules/                     # shared system modules
│   ├── default.nix              # module summary
│   ├── niri.nix                 # niri + greetd login
│   ├── audio.nix                # PipeWire
│   └── laptop.nix               # power / bluetooth / fwupd
└── home/                        # user environment (Home Manager)
    ├── default.nix
    ├── niri.nix                 # links niri config (incl. host's niri-hardware.kdl)
    ├── noctalia.nix             # Noctalia config
    └── niri/                    # shared niri KDL config
        ├── config.kdl           # main config (includes sub-files)
        ├── binds.kdl            # keybindings
        ├── startup.kdl          # startup commands
        └── windowrule.kdl       # window / layer rules
```

## Disk layout (tmpfs + btrfs subvolumes)

- The root filesystem `/` is mounted as **tmpfs** and is wiped on every reboot ("erase your darlings").
- Data that must persist lives on dedicated btrfs subvolumes:

| subvolume | mountpoint | contents |
|-----------|------------|----------|
| `@nix`  | `/nix`  | Nix store (must persist) |
| `@var`  | `/var`  | logs, runtime state |
| `@etc`  | `/etc`  | machine-id, SSH host keys, etc. |
| `@home` | `/home` | user data |

`/boot` is a separate EFI system partition (ESP); a dedicated swap partition is configured for hibernation.

## Installation

disko performs partitioning + formatting + subvolume creation + mounting in one step (it wipes the target disk — fresh installs only).

1. Boot the NixOS installation ISO, connect to the network, and `git clone` this repo.
2. Change `device` in `hosts/laptop/disko-fs.nix` to your actual disk (see `lsblk`).
3. Partition, format, create subvolumes and mount:
   ```bash
   nix run github:nix-community/disko -- --mode disko ./hosts/laptop/disko-fs.nix
   ```
4. Generate the hardware config and fill in the UUIDs:
   ```bash
   nixos-generate-config --root /mnt
   blkid
   ```
   Fill the btrfs partition UUID into `<BTRFS-UUID>`, the ESP UUID into `<ESP-UUID>`, and the swap partition UUID into `<SWAP-UUID>` in `hosts/laptop/hardware-configuration.nix`.
5. Install:
   ```bash
   sudo nixos-install --flake .#laptop
   ```
6. Reboot and log in via greetd into niri.

## Things to change before first use

| Location | What |
|----------|------|
| `hosts/laptop/disko-fs.nix` | target disk `device` |
| `hosts/laptop/hardware-configuration.nix` | disk UUIDs (see `blkid`) |
| `hosts/laptop/default.nix` | user name `userName`, `hostName`, `stateVersion` |
| `hosts/laptop/niri-hardware.kdl` | display resolution / scale |
| `home/noctalia.nix` | wallpaper path, theme |
| `chinese.nix` | input method (e.g. Rime Wusong Pinyin if desired) |

## Notes & optional enhancements

- **Noctalia binary cache**: configured in `flake.nix` / `hosts/laptop/default.nix` via Cachix; the `noctalia` input is pinned to the `cachix` branch and intentionally does **not** set `follows` on nixpkgs (otherwise the cache is lost).
- **impermanence**: this setup persists state directly with btrfs subvolumes. If you want `/etc` and `/home` on tmpfs too, persisting only a few files, add `nix-community/impermanence`.
- **polkit auth agent**: niri ships no graphical polkit agent; add one (e.g. `polkit_gnome`) if you need GUI privilege prompts.
- **XWayland**: off by default; configure `xwayland-satellite` per the niri docs if you need X11 apps.
- **Lock screen**: Noctalia has a built-in lock screen bound to `Super+Alt+L`; lid-close suspend is handled by logind.
