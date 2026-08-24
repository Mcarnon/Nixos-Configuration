# Maintenance

How to keep this NixOS system up to date and how the repo is organised.

## Layout (who owns what)

| Path | Responsibility |
|------|----------------|
| `flake.nix` | Inputs (nixpkgs / home-manager / noctalia) + `nixosConfigurations.laptop` |
| `hosts/laptop/` | **Machine-specific** files |
| `hosts/laptop/default.nix` | Host identity (user, hostname, timezone, stateVersion) + wiring |
| `hosts/laptop/hardware-configuration.nix` | Disk mounts / initrd modules / firmware. **Holds the real UUIDs on the laptop** |
| `hosts/laptop/disko-fs.nix` | Partitioning as code (run once at install) |
| `hosts/laptop/intel.nix` | Intel CPU microcode + Iris Xe graphics / VA-API |
| `hosts/laptop/niri-hardware.kdl` | Screen resolution / scale |
| `modules/` | **Reusable, host-agnostic** system modules (boot / network / nix / cli / diagnostics / niri / audio / laptop / ssh) |
| `locales/` | Locale / input-method / fonts |
| `home/` | Per-user Home Manager config |
| `scripts/sync.sh` | rsync + rebuild to another machine |

Rule of thumb: if it's true for *this specific laptop only*, it belongs in
`hosts/laptop/`. If it could apply to any machine, put it in `modules/`.

## Day-to-day: edit → rebuild

```bash
cd ~/Nixos-Configuration          # or wherever the repo lives on the laptop
git add -A                        # flakes only see git-tracked files
sudo nixos-rebuild switch --flake .#laptop
```

> With the tmpfs root, only `/nix`, `/var`, `/etc`, `/home` persist across
> reboot. Keep the repo under `~/` (the `@home` subvolume) so it survives.

If you edit files but `nixos-rebuild` ignores them, they're probably untracked
by git — run `git add -A` first.

## Updating packages / system

```bash
nix flake update                          # bump all inputs
nix flake lock --update-input nixpkgs     # or update a single input
sudo nixos-rebuild switch --flake .#laptop
```

- Home Manager packages update with the same rebuild (`useGlobalPkgs = true`).
- **Roll back**: `sudo nixos-rebuild switch --rollback`, or pick the previous
  entry in the systemd-boot menu at boot.
- List generations: `sudo nix-env --list-generations -p /nix/var/nix/profiles/system`.

## Garbage collection / disk space

Automatic weekly GC is configured in `modules/nix.nix`. Manual cleanup:

```bash
sudo nix-collect-garbage -d       # delete unreferenced store paths + old profiles
sudo nix store optimise           # dedupe (auto-optimise-store is already on)
```

## Hardware maintenance

- **Firmware**: `sudo fwupdmgr refresh && sudo fwupdmgr update` (BIOS / SSD / etc.).
- **CPU microcode**: `hardware.cpu.intel.updateMicrocode` (in `intel.nix`) — ships with the kernel.
- **GPU / VA-API**: `intel-media-driver` (iHD, Iris Xe) is configured in `intel.nix`; verify with `vainfo`.
- **Diagnostics** (installed by `modules/diagnostics.nix`):
  `lspci`, `lsusb`, `dmidecode`, `smartctl -a /dev/nvme0n1`, `nvme list`,
  `sensors`, `powertop`, `inxi -F`.
- **Audio** (Huawei / Intel SOF — PipeWire in `modules/audio.nix`):
  ```bash
  lspci -nnk | grep -iA3 audio                    # kernel sees the sound card?
  aplay -l                                        # ALSA devices
  wpctl status                                    # wireplumber routing
  systemctl --user status pipewire pipewire-pulse wireplumber
  ```

## Configuration maintenance

- Everything is declarative: edit `.nix`, `git add`, `nixos-rebuild switch`.
- **Machine-specific UUIDs live only in `hardware-configuration.nix`.** Before
  first install, fill the real btrfs/ESP UUIDs (from `blkid`) there. The repo
  must not ship placeholder `<BTRFS-UUID>` / `<ESP-UUID>` values — a rebuild
  with placeholders produces a system that can't mount `/nix` etc.
- `system.stateVersion` and `home.stateVersion` are pinned at first install and
  must **not** be bumped on upgrade (they control upgrade-compat behaviour).

## Syncing to the laptop

If you edit on another machine and deploy via `scripts/sync.sh`:

```bash
./scripts/sync.sh deploy          # rsync to remote + remote rebuild
```

Caveat: `sync.sh` rsyncs with `--delete` and excludes `.git`, so the remote copy
is a plain path flake (no git metadata). If `hardware-configuration.nix` differs
between machines (real UUIDs vs placeholders), keep the real-UUID copy on the
laptop and re-apply it after a push — or commit the real UUIDs into the repo.

## Secrets

Never commit passwords or SSH private keys. `~/.ssh/` and passwords are managed
outside Nix for now. If you later need secrets in the config, use `agenix` or
`sops-nix`.
