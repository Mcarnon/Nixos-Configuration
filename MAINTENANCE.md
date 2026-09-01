# Maintenance

How to keep this NixOS system up to date and how the repo is organised.

## Layout (who owns what)

| Path | Responsibility |
|------|----------------|
| `flake.nix` + `flake-parts/` | Standardized entry (flake-parts perSystem memoization, `nix flake check`); `hosts.nix`/`packages.nix`/`checks.nix` |
| `lib/` | Helpers (`mkHost`, hardware helpers) — cross-host reuse |
| `pkgs/` + `pkgs/default.nix` | Overlay (`overlays.default` = `{miyu}`) — single audit surface for custom binaries |
| `roles/nixos/` + `roles/home/` | Host/user composition (base/desktop) |
| `hosts/laptop/` | **Machine-specific** (hardware-configuration/disko-fs/niri-hardware + `default.nix` which picks `roles/nixos/desktop` + `hardware.intel.enable`) |
| `modules/nixos/` | Reusable system modules: `core/` (boot/nix/shell/persist/kernel/cli/diagnostics), `desktop/` (niri/ly/audio), `hardware/` (intel/nvidia/power/disko), `network/` (manager/openssh/firewall), `security/` (secrets/hardening/sops), `i18n/` -> `locales/` |
| `modules/home/` | Reusable HM modules: `shell/` (fish/tools, SHORiN 风格函数), `desktop/` (niri/waybar/fuzzel/lock/mako/appearance), `apps/` (cli/gui/media/network/ai), `services/` (miyu) |
| `modules/_templates/` | 新模块脚手架 |
| `locales/` | Locale / input-method / fonts (canonical，`modules/nixos/i18n` 垫片) |
| `home/` | Per-user HM entry — `home/files/*` (miyu/f/fwatch/foot/fuzzel/...) + `home/niri/*` (kdl + hyprlock + scripts) |
| `docs/` | `QUICK_START.md` / `STRUCTURE.md` / `MIGRATION.md` |
| `checks/` | NixOS VM tests (e.g. `miyu.nix`) wired as `perSystem.checks` |
| `.github/workflows/ci.yml` | `nix flake check` + `nix fmt --check` |
| `scripts/sync.sh` | rsync + rebuild to another machine |

Rule of thumb: `hosts/<host>/` = 身份+硬件+选 `roles/`；`modules/nixos+home` = 按域可复用；`roles/` = 组合。

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

Automatic weekly GC is configured in `modules/nixos/core/nix.nix`. Manual cleanup:

```bash
sudo nix-collect-garbage -d       # delete unreferenced store paths + old profiles
sudo nix store optimise           # dedupe (auto-optimise-store is already on)
```

## Hardware maintenance

- **Firmware**: `sudo fwupdmgr refresh && sudo fwupdmgr update` (BIOS / SSD / etc.).
- **CPU microcode**: `hardware.intel.enable = true` (`modules/nixos/hardware/intel.nix`) — HAL, set per host, microcode ships with kernel.
- **GPU / VA-API**: `intel-media-driver` (iHD, Iris Xe) via same HAL; verify with `vainfo`.
- **Diagnostics** (installed by `modules/nixos/core/diagnostics.nix`):
  `lspci`, `lsusb`, `dmidecode`, `smartctl -a /dev/nvme0n1`, `nvme list`,
  `sensors`, `powertop`, `inxi -F`.
- **Audio** (Huawei / Intel SOF — PipeWire in `modules/nixos/desktop/audio.nix`):
  ```bash
  lspci -nnk | grep -iA3 audio                    # kernel sees the sound card?
  aplay -l                                        # ALSA devices
  wpctl status                                    # wireplumber routing
  systemctl --user status pipewire pipewire-pulse wireplumber
  ```

## Configuration maintenance

- Everything is declarative: edit `.nix`, `git add`, `nixos-rebuild switch`.
- **Machine-specific UUIDs live only in `hardware-configuration.nix`.** Before
  first install, fill the real ROOT/ESP UUIDs (from `blkid`) there. The repo
  must not ship placeholder `<ROOT-UUID>` / `<ESP-UUID>` values — a rebuild
  with placeholders produces a system that can't mount `/nix` or `/boot`.
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

- Binary via overlay `pkgs.miyu` (`pkgs/miyu` v0.4.5, `nix build .#miyu`). Update: bump `version` + `hash` in `pkgs/miyu/default.nix` from GitHub asset `miyu-*.pkg.tar.zst`.
- Fish hook `home/files/miyu.fish` → `xdg.configFile fish/conf.d/zz-miyu.fish` in `modules/home/services/miyu.nix` (loads after starship). Never run `miyu fish-init` under HM. Diagnostics: `miyu --shell-intercept --shell fish -- <cmd>` (hook silences stderr).
- First-run init: `modules/home/services/miyu.nix` `home.activation.miyuInit` runs `miyu init` if `~/.miyu` missing (also `miyu daemon start`). Verify `miyu paths` / `miyu -h`.
- Model / opencode / prompt: `miyu config` (TUI, DB at `~/.miyu`) → 供应商和模型 (default opencode public API; add own OpenAI-compatible or enable Claude Code provider) → 自定义提示词 (new persona) + 用户身份. Also `miyu models`, `miyu daemon logs request`, `miyu export --dry-run`.

## Performance & security baselines

- **Performance**: `flake-parts` perSystem caching, `nix.settings` (`max-jobs auto`, `cores 0`, `auto-optimise-store`, `keep-derivations false`), `nix.gc` weekly, `zramSwap` zstd 25%, `boot.kernel.sysctl` BBR/fq + `vm.swappiness 10`, `services.resolved` cache, CN mirror substituters.
- **Security**: `networking.firewall` closed (only 22), `services.openssh` `PermitRootLogin no` (flip `PasswordAuthentication` to `false` after agenix), `age` via `agenix` (tmpfs `/run/agenix.d`), `security.sudo.execWheelOnly`, `boot.kernel.sysctl` (`kptr_restrict`, `ptrace_scope`), `nix.settings.trusted-users = [ root @wheel ]`, `nix.channel.enable = false`.
- **CI**: `nix flake check` runs `checks/miyu.nix` VM smoke + `nix fmt --check`; add more VM tests under `checks/` and wire in `flake-parts/checks.nix`.

## Secrets

Never commit passwords or SSH private keys. Secrets are managed with **agenix**
(see `modules/nixos/security/secrets.nix`): encrypted `.age` blobs live in `secrets/`, and only
the target host's age identity (by default `~/.ssh/id_ed25519`) can decrypt
them. The plaintext is only ever written to `/run/agenix.d/` (tmpfs). To add a
secret, follow the steps at the top of `modules/security/secrets.nix`.
