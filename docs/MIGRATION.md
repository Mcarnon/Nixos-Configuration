# 迁移指南

旧 `profiles/`、`home/profiles/`、`modules/default.nix`、`modules/{nixos,home}/default.nix`
这些垫片/聚合已删除：

- 主机入口：`hosts/laptop/default.nix` 直接 `imports = [ ../../roles/nixos/desktop.nix ]`
- home 入口：`home/default.nix` 直接 `imports = [ ../roles/home/desktop.nix ]`
- 新增域模块：放 `modules/nixos/<domain>/` 或 `modules/home/<domain>/`，并在同域目录的 `default.nix` 注册

`locales/` 仍是 locale/输入法/字体框架的 canonical 位置；`modules/nixos/i18n/` 是指向它的垫片。

## 桌面壳：Clavis -> iNiR（2026-09）

Clavis 时代的自建打包/脚本已经全部删除，替换成上游 iNiR flake：

- `flake.nix`：三个 `flake = false` 源码输入（`clavis-shell` / `key-cli` /
  `keytop`）换成 `inir = github:snowarch/iNiR`。
- `pkgs/{clavis-shell,key-cli,keytop,libcava}/` 已删除；`pkgs/default.nix` 只剩
  `pkgs.miyu`。
- `modules/home/desktop/clavis/` -> `modules/home/desktop/inir/`（导入上游
  `homeManagerModules`，保留 `inir-session-env` 包装这一处本机加固）。
- 壁纸选择器 / 半小时轮换 / `scan-tones` 色调库 / `clavis-theme-sync` 删除：
  iNiR 自带选择器（grid/coverflow/launcher）、`random`、`browse live`，以及
  gtk/终端/编辑器的按壁纸取色。
- niri 侧不再有运行时生成的 kdl 片段：`home/niri/inir-static.kdl` 取代
  `clavis-static.kdl`（纯静态），主配置里三行 `include optional=true
  "clavis/*.kdl"` 全部删除。
- 快捷键从 `key ipc call <target> <method>` 换成 `inir <target> <function>`
  （映射见 `docs/DESKTOP.md` 的键位表）。

手动收尾（在 NixOS 机器上）：

1. `nix flake lock`（本地 flake 会在下次 build 时自动 re-lock，但显式跑一次
   能让 `flake.lock` 里的 `inir` 条目和 git 状态一致）。
2. 删掉旧外壳留下的运行时垃圾（新的 iNiR 会自己重建）：

   ```bash
   rm -rf ~/.config/clavis ~/.config/niri/clavis ~/.local/state/clavis \
     ~/.config/wallpaper-tones.txt ~/.config/kitty/themes/Matugen.conf
   ```

3. 旧的 `~/.config/clavis/config.json` 里的壁纸目录/主题偏好不会自动迁移；
   在 `inir settings` 里重设一次壁纸目录（`~/Pictures/Wallpapers`）。
