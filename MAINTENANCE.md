# Maintenance

How to keep this NixOS system up to date and how the repo is organised.

## Layout (who owns what)

| Path | Responsibility |
|------|----------------|
| `flake.nix` | Inputs (nixpkgs / home-manager / noctalia) + `nixosConfigurations.laptop` |
| `hosts/laptop/` | **Machine-specific** files |
| `hosts/laptop/default.nix` | Host identity (user, hostname, timezone, stateVersion) + wiring |
| `hosts/laptop/hardware-configuration.nix` | Disk mounts / LUKS unlock / initrd modules / firmware. **Holds the real UUIDs on the laptop** |
| `hosts/laptop/disko-fs.nix` | Partitioning as code (run once at install; LUKS + btrfs subvolumes + swapfile) |
| `hosts/laptop/intel.nix` | Intel CPU microcode + Iris Xe graphics / VA-API |
| `hosts/laptop/niri-hardware.kdl` | Screen resolution / scale |
| `modules/` | **Reusable, host-agnostic** system modules (boot / network / nix / packages / shell / snapshot / secrets / niri / audio / laptop / ssh) |
| `pkgs/miyu` | Miyu derivation (prebuilt Arch release, autoPatchelf) |
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
- **Diagnostics** (installed by `modules/packages/diagnostics.nix`):
  `lspci`, `lsusb`, `dmidecode`, `smartctl -a /dev/nvme0n1`, `nvme list`,
  `sensors`, `powertop`, `inxi -F`.
- **LUKS**: the disk is unlocked at boot (passphrase) as `/dev/mapper/cryptroot`.
  `sudo cryptsetup luksDump /dev/nvme0n1p2` shows header info; add/remove a
  passphrase slot with `cryptsetup luksAddKey` / `luksRemoveKey`.
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
  first install, fill the real LUKS/ESP UUIDs (from `blkid`) there. The repo
  must not ship placeholder `<LUKS-UUID>` / `<ESP-UUID>` values — a rebuild
  with placeholders produces a system that can't unlock the disk / mount `/nix`.
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

## Miyu AI assistant

- Binary at `pkgs/miyu` (v0.4.5, `nix build .#miyu`). Update: bump `version` + `hash` in `pkgs/miyu/default.nix` from the GitHub release asset `miyu-*.pkg.tar.zst`.
- Fish hook is `home/miyu.fish` → `xdg.configFile fish/conf.d/zz-miyu.fish` (declarative `miyu fish-init`; loads after starship). Never run `miyu fish-init` imperatively under HM — it would be overwritten. Diagnostics: if typing does nothing, run `miyu --shell-intercept --shell fish -- <cmd>` to see the error (the hook silences stderr).
- First-run init: `home.activation.miyuInit` runs `miyu init` if `~/.miyu` is missing. Manual alternative: `miyu init` or `miyu daemon start` (first start also inits). Verify with `miyu paths` / `miyu -h`.
- Model / opencode / prompt: `miyu config` (TUI) is the intended config path — DB is at `~/.miyu`, not a plain file. Steps after rebuild: open a new shell → `miyu config` → 供应商和模型 (add your own OpenAI-compatible endpoint or enable Claude Code provider which reuses local `claude` subscription) → 自定义提示词 (new persona; default is read-only) + 用户身份. Also: `miyu models` to switch without TUI, `miyu daemon logs request` to inspect real LLM requests, `miyu export --dry-run` before migration.

## Secrets

Never commit passwords or SSH private keys. Secrets are managed with **agenix**
(see `modules/secrets.nix`): encrypted `.age` blobs live in `secrets/`, and only
the target host's age identity (by default `~/.ssh/id_ed25519`) can decrypt
them. The plaintext is only ever written to `/run/agenix.d/` (tmpfs). To add a
secret, follow the steps at the top of `modules/secrets.nix`.
