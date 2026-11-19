# Maintenance

How to keep this NixOS system up to date and how the repo is organised.

## Layout (who owns what)

| Path | Responsibility |
|------|----------------|
| `flake.nix` + `flake-parts/` | Standardized entry (flake-parts perSystem memoization, `nix flake check`); `hosts.nix`/`packages.nix`/`checks.nix` |
| `lib/` | Helpers (`mkHost`, hardware helpers) — cross-host reuse |
| `pkgs/` + `pkgs/default.nix` | Overlay (`overlays.default` = `{miyu, splayer, libcava, m3shapes, clavisShell, keyCli, dsh}`；`dsh` 是转接上游 overlay 得到的 scope) — single audit surface for custom binaries |
| `roles/nixos/` + `roles/home/` | Host/user composition (base/desktop) |
| `hosts/laptop/` | **Machine-specific** (hardware-configuration/disko-fs/niri-hardware + `default.nix` which picks `roles/nixos/desktop` + `hardware.intel.enable`) |
| `modules/nixos/` | Reusable system modules: `core/` (boot/nix/shell/persist/kernel/cli/diagnostics), `desktop/` (niri/ly/audio), `hardware/` (intel/nvidia/power/disko), `network/` (manager/openssh/firewall), `security/` (secrets/hardening/sops), `i18n/` -> `locales/` |
| `modules/home/` | Reusable HM modules: `shell/` (fish/tools, SHORiN 风格函数), `desktop/` (niri/waybar/fuzzel/lock/mako/appearance), `apps/` (cli/gui/media/network/ai/dsh), `services/` (miyu) |
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
- **Gaomon (高漫) M6 tablet**: `hardware.gaomon.enable = true`
  (`modules/nixos/hardware/tablet.nix`) enables OpenTabletDriver instead of the
  vendor driver (which has no Linux build and mis-reads the X11 cursor position
  under Wayland — the pen jumps back to a fixed spot on niri). Tune mappings in
  `otd-gui`; its settings live in `~/.config/OpenTabletDriver/` as runtime files,
  so do not symlink them from the store. The toggle also blacklists
  `hid-uclogic`/`wacom` **globally**: if OTD ever stops recognizing the tablet,
  set `hardware.opentabletdriver.blacklistedKernelModules = []` and turn the
  toggle off to fall back to the in-kernel driver. The M6's touch ring/wheel is
  not parsed by OTD — only the pen and its 13 aux buttons.
- **Diagnostics** (installed by `modules/nixos/core/diagnostics.nix`):
  `lspci`, `lsusb`, `dmidecode`, `smartctl -a /dev/nvme0n1`, `nvme list`,
  `sensors`, `powertop`, `inxi -F`.
- **Audio** (Huawei / Intel SOF — PipeWire in `modules/nixos/desktop/audio.nix`):
  This board's DSDT declares an Everest ES8336 codec at `\_SB_.PC00.I2C2.ESSX`,
  but ACPI I2C2 is PCI `00:15.2`, a controller Quanta never exposed here (only
  I2C0 / `00:15.0` exists). The codec is unreachable, yet SOF matches machine
  drivers by ACPI HID, so it kept picking the unusable `sof-essx8336` driver,
  which then asked for `intel/sof-tplg/sof-tgl-es8336-dmic2ch.tplg` — a name
  current sof-bin releases no longer ship — and the probe died with `-ENOENT`:
  no sound card at all.
  Fix: `hosts/laptop/acpi-override.nix` renames that phantom HID in the DSDT
  (`hosts/laptop/acpi/DSDT.raw` + `patch-dsdt.py`) and injects the patched
  table through `boot.initrd.prepend`. With the ES8336 match gone, SOF falls
  back to the HDA machine driver (`skl_hda_dsp_generic` +
  `sof-hda-generic-2ch.tplg`), which drives the codecs that really are wired
  (HDA #0 Conexant SN6140, HDA #2 Intel HDMI) and the PCH digital mic array.

  While the override is being verified, `hosts/laptop/hardware-configuration.nix`
  still pins `options snd-intel-dspcfg dsp_driver=1` (legacy HDA) so audio
  cannot regress; **delete that block once the override is confirmed** to hand
  the device back to SOF.
  ```bash
  ls /sys/bus/acpi/devices | grep ESSX     # expect ESSX8337:00, no ESSX8336:00
  journalctl -k -b | grep -i 'Table Upgrade'   # ACPI: Table Upgrade: ... DSDT
  lspci -nnk | grep -iA3 audio             # snd_hda_intel vs sof-audio-*
  aplay -l && cat /proc/asound/cards       # ALSA devices
  wpctl status                             # sinks/sources (DMIC = 2nd source)
  journalctl -k -b | grep -iE 'snd|sof'    # machine driver / topology picked
  ```
  After a BIOS update the stored DSDT is stale — re-dump and re-patch (the
  override only applies while its OEM revision is newer than the firmware's,
  which the patch script takes care of):
  ```bash
  sudo cp /sys/firmware/acpi/tables/DSDT hosts/laptop/acpi/DSDT.raw
  python3 hosts/laptop/acpi/patch-dsdt.py hosts/laptop/acpi/DSDT.raw /tmp/check.aml
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

## DeepSeek Harness (`dsh`)

- 包来自 flake 输入 `deepseek-harness`（github:moraxyc/deepseek-harness.nix，MIT，只打包不 fork）。更新：`nix flake update deepseek-harness`。别自己 `callPackage` 它的 pkgs。
- `pkgs/default.nix` 里 `dsh = (inputs."deepseek-harness".overlays.default final prev).dsh;` —— 两个坑：上游 overlay 返回 `{ dsh = <scope>; }`，必须取 `.dsh`（否则 `pkgs.dsh.bundles` attribute missing、上游 `lib.mkPackageOption pkgs.dsh` 报 “not of type 'package'”）；必须传本仓库的 `final`/`prev`，否则 scope 退回上游 nixpkgs。同时**不要**再导入上游 `nixosModules.default`，它会重复叠 overlay。
- **`bundles.tui` 被本地覆盖成 dsh-TUI 0.12.0**（`pkgs/dsh-tui/`），这是临时补丁：`nix flake update deepseek-harness` 到内核 0.2.0-rc.2 后，上游 `pkgs/bundles/tui` 还钉在 0.11.2，它的 `peerDependencies` 只到 0.2.0-rc.1，`dshBundleCheckHook` 在 installCheckPhase 判定不兼容直接 exit 1（`nix run #presets.tui` 同样坏）。0.12.0 的 peer 已含 rc.2。判据：上游 bundles.tui 版本 >= 0.12.0（或内核 peer 检查不再失败）就删掉 `pkgs/dsh-tui/` 与 `pkgs/default.nix` 里的 `tui` 覆盖。改 hash 的办法：`hash = lib.fakeHash` 让报错打印 `got:`，填回去；`src` 先于 `pnpmDeps`（后者依赖前者）。
- 上面那个 `bundles.tui` 覆盖要**两处**都改（`pkgs/default.nix`：`bundles = super.bundles.overrideScope …` **加** `dsh = super.dsh.override { bundles = self.bundles; }`）。只改 `bundles.tui` 消费方看到 0.12.0，但 `scope.dsh` 在 scope 建立时就通过 callPackage 绑定了**原始** bundles（上游 `overlays/default.nix` 的 `directoryPackages`），`overrideScope` 事后改 `bundles` 不会回溯改它内部的 `tuiBundle`（`pkgs/dsh/package.nix:83`）。`profiles.nix` 把 needsTui 的 `tuiBundle` 和 profile 自己声明的 bundles 一起 `lib.unique` 收集，resolver 于是报 `conflicting bundle metadata for @deepseek-harness-tui/dsh-tui: 0.11.2 … vs 0.12.0 …`，`dsh-profile-*-template` 失败。
- `modules/home/apps/dsh.nix` 导入上游 `homeModules.default`（`programs.dsh` + profile 物化到 `~/.dsh/profiles/<materializedName>`）。只走 HM 一层，系统级不装。
- 该文件里还有 `package = pkgs.dsh.dsh.overrideAttrs …` 注入 `dshBundleCheckTtyProfiles`：上游 `lib/mk-dsh-runtime.nix` 给 runtime 包传 `profiles = { }`（profile 由 `profileSeeder` 单独物化），于是 `dshBundleCheckTtyProfiles` 为空，`dshBundleCheckHook` 只能扫 `$DSH_HOME/profiles/*` 自动发现 profile，而发现出来的名字三个名单里都没有，被当普通 CLI 直接 `dsh --profile nix-tui --help` —— 没有 pty，Ink 抛 `Raw mode is not supported on the current process.stdin`，installCheckPhase 失败。名单用上游 `profileRequiresTty` 的同一套判据自己算（`profile.requiresTty` / `profile.requiresTui` / 任一 bundle 的 `passthru.requiresTui|requiresTty`），写进 `overrideAttrs` 才能活过 `mkDshRuntime` 的 `.override { … }`（override 只换函数实参，`__overrideAttrs` 最后才跑）。注意 `pkgs.dsh` 是 scope，包本身是 `pkgs.dsh.dsh`。
- Profile 是 `mutable`：Nix 只在目录不存在时 seed，之后 `dsh plugin` / Settings UI 的改动不会被覆盖。重新 seed：`rm -rf ~/.dsh` 后 `nixos-rebuild switch`（HM 激活会跑 `dsh-sync-profiles`）。
- Bundle 在 `profiles.tui.bundles` 里声明（插件式，按列表顺序覆盖）：`tui` 已在用；`subscriptions`（ChatGPT/Claude/Copilot 订阅 OAuth）、`memento`（跨会话记忆）、`modsearch`（内置搜索）、`subagent-codex`/`subagent-claude-code`（后者 unfree，需 `nixpkgs.config.allowUnfreePredicate`）都没启用。
- API key 不要进 Nix：官方 DeepSeek 平台申请后在 dsh 设置里填（或 `export DEEPSEEK_API_KEY`）。想用订阅免 key 就换 `subscriptions` bundle。
- 上游 Cachix（`deepseek-harness-nix.cachix.org`）已写进 `flake.nix` 的 `nixConfig`，但 **bundle 组合后的 dsh 大概率不在缓存里**：第一次 rebuild 要本地 build 一千多个 node 派生，提前 `nix build .#dsh` 预热。
najiu- 想试上游其它组合而不动本仓库：`nix run github:moraxyc/deepseek-harness.nix#presets.tui --accept-flake-config`。

## FlClash

- 包是 `pkgs/flclash/default.nix`：解包官方 `FlClash-<ver>-linux-amd64.deb`（nixpkgs 的 flclash 已因用户少被移除，从源码重建要整套 Flutter + Go core + Rust API，不值得）。升级只改 `version` + `hash`：
  ```bash
  nix store prefetch-file --json --hash-type sha256 \
    https://github.com/chen08209/FlClash/releases/download/v<ver>/FlClash-<ver>-linux-amd64.deb
  ```
  两个打包坑：`librust_api.so` 由 `RustLib.init()` **dlopen**（不读 RUNPATH），wrapper 必须 `--prefix LD_LIBRARY_PATH`；`libdartjni.so` 的 `NEEDED libjvm.so` 在 Linux 上根本不会被加载，用 `autoPatchelfIgnoreMissingDeps` 忽略，别拖 JDK 进来。
- FlClash 是**唯一**的代理 GUI（HM 包 + `modules/nixos/desktop/flclash.nix` 的 `flclash-helper`）。Clash Verge Rev 已从配置移除（`programs.clash-verge` 与 `modules/nixos/desktop/clash-verge.nix` 都已删），但 `~/.config/clash-verge` 里的旧配置/订阅不会被 Nix 删，想彻底清就自己 `rm -rf`，并确认 `systemctl status clash-verge-service` 已不存在。
- 终端代理：fish `proxy_on` / `proxy_off` 默认端口改成 **7890**（FlClash 的 mixed 端口；旧的 7897 是 Clash Verge 的默认值）。
- TUN 模式的约定（改这里前先读 `modules/nixos/desktop/flclash.nix` 顶部注释）：FlClash 的 GUI 只跑用户态，root Core 由 `flclash-helper.service` 拉起；helper 在 `/run/flclash/helper.sock` 上服务，只认 peer uid == `FLCLASH_HELPER_OWNER_UID` 的连接。GUI 先 ping 这个 socket，拿到 ok 就**不会**去跑 `pkexec FlClashHelperService install` —— 所以 NixOS 侧声明式提供同名 unit 就绕过了整个提权安装流程。
- 三条硬约束：unit 名必须叫 `flclash-helper`；`ExecStart` 必须是同一个 store 路径的 `opt/FlClash/FlClashHelperService`（GUI 会把自己 `dirname` 和 ping 返回的路径逐字比对，helper 还会校验同目录 `FlClashCore` 的 SHA256 和 `manifest.json` 的 `coreSha256`）；`FLCLASH_HELPER_OWNER_UID/GID` 必须非 0。任何一条对不上，GUI 会静默回落到用户态 Core（TUN 开关用不了），`journalctl -u flclash-helper` 里只有 helper 自己的日志。
- 不要给这个 unit 加 `PrivateTmp` / `ProtectSystem` / `ProtectHome`：Core 要在宿主 `/tmp` 建 `/tmp/FlClashSocket_<id>.sock`（属主得能连），还要动 nftables/iptables 和路由表。
- 排查：`systemctl status flclash-helper`、`journalctl -u flclash-helper`、以属主身份 `curl --unix-socket /run/flclash/helper.sock 'http://localhost/ping?coreSha256=<manifest.json 里的值>'`（Host 只接受 127.0.0.1 / localhost / FlClashHelperService，带 `origin` 头会被 403；返回 200 的 body 是 helper 路径、头里的 `x-flclash-helper-protocol` 是协议版本 6）。GUI 侧日志在 FlClash 的 `logs/`，关键字 `helper ping failed` / `helper protocol mismatch` / `helper executable path mismatch` / `Helper Core SHA256 mismatch`。

## Performance & security baselines

- **Performance**: `flake-parts` perSystem caching, `nix.settings` (`max-jobs auto`, `cores 0`, `auto-optimise-store`, `keep-derivations true` — 防止 GC 删掉仍被现有 `.drv` 引用的输入派生), `nix.gc` weekly, `zramSwap` zstd 25%, `boot.kernel.sysctl` BBR/fq + `vm.swappiness 10`, `services.resolved` cache, CN mirror substituters.
- **Security**: `networking.firewall` closed (only 22), `services.openssh` `PermitRootLogin no` (flip `PasswordAuthentication` to `false` after agenix), `age` via `agenix` (tmpfs `/run/agenix.d`), `security.sudo.execWheelOnly`, `boot.kernel.sysctl` (`kptr_restrict`, `ptrace_scope`), `nix.settings.trusted-users = [ root @wheel ]`, `nix.channel.enable = false`.
- **CI**: `nix flake check` runs `checks/miyu.nix` VM smoke + `nix fmt --check`; add more VM tests under `checks/` and wire in `flake-parts/checks.nix`.

## Secrets

Never commit passwords or SSH private keys. Secrets are managed with **agenix**
(see `modules/nixos/security/secrets.nix`): encrypted `.age` blobs live in `secrets/`, and only
the target host's age identity (by default `~/.ssh/id_ed25519`) can decrypt
them. The plaintext is only ever written to `/run/agenix.d/` (tmpfs). To add a
secret, follow the steps at the top of `modules/security/secrets.nix`.
