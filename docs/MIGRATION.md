# 迁移指南

旧 `profiles/`、`home/profiles/`、`modules/default.nix`、`modules/{nixos,home}/default.nix`
这些垫片/聚合已删除：

- 主机入口：`hosts/laptop/default.nix` 直接 `imports = [ ../../roles/nixos/desktop.nix ]`
- home 入口：`home/default.nix` 直接 `imports = [ ../roles/home/desktop.nix ]`
- 新增域模块：放 `modules/nixos/<domain>/` 或 `modules/home/<domain>/`，并在同域目录的 `default.nix` 注册

`locales/` 仍是 locale/输入法/字体框架的 canonical 位置；`modules/nixos/i18n/` 是指向它的垫片。

## 桌面壳：iNiR -> Clavis（2026-09）

Clavis Shell + key-cli 回来了，但这次连同 M3Shapes 一起自建打包（上游都没给
NixOS/Home Manager 模块）：

- `flake.nix`：`inir = github:snowarch/iNiR` 换成三个输入
  —— `clavis-shell`/`key-cli` 是 `flake = false` 的源码输入，
  `m3shapes` 用 `github:soramanew/m3shapes`（它的 nixpkgs follows 本 flake）。
- `pkgs/{clavis-shell,key-cli}/` 重新落地；`pkgs/libcava/` 仍然不需要
  （用 nixpkgs 的 `libcava`）。`pkgs/default.nix` = `miyu` + `clavisShell` +
  `keyCli`。`keyCli` 里带手写的 `key` wrapper（PATH/QML_IMPORT_PATH/
  XDG_CONFIG_DIRS）。
- `modules/home/desktop/inir/` -> `modules/home/desktop/clavis/`：不再导入上游
  `homeManagerModules`，服务、环境、种子都自己写（上游 unit 只作为参考，
  声明式 unit 的好处是 ExecStart 能过 `clavis-session-env`）。**没有
  `programs.clavis.enable`**：旧模块靠上游的 opt-in，这个模块是「被 import 就
  生效」的直接配置模块，和本仓库其它桌面模块一致。
- niri 侧：`home/niri/inir-static.kdl` 改回 `clavis-static.kdl`；主配置新增
  `include optional=true "clavis/effects.kdl"`（Clavis 自己写这个片段）；壁纸
  layer 规则改成 `clavis-wallpaper`（`Modules/Wallpaper/DesktopWallpaper.qml`
  的 `WlrLayershell.namespace`）。
- 快捷键：`inir <target> <function>` -> `key ipc call <target> <method>`，
  映射见 `docs/DESKTOP.md` 的键位表。iNiR 独有的
  `wallpaperSelector random` / `browse live` 没有对应项，已删除。
- kitty 主题路径改了：iNiR 写 `~/.config/kitty/themes/current-theme.conf`，
  Clavis 的 matugen post_hook 写 `~/.config/kitty/themes/Matugen.conf` 再
  `cp` 到 `~/.config/kitty/current-theme.conf`，所以 `kitty.conf` 的 include
  和 `home/files/kitty/current-theme.conf` 的种子注释一起改了。
- `foot.ini` / `fuzzel.ini` 删掉了 iNiR 专用的 `include` 行：Clavis 的 matugen
  模板里没有这两个程序，include 一个永远不存在的文件只会每次启动报警告。

手动收尾（在 NixOS 机器上）：

1. `nix flake lock`（显式跑一次，让 `flake.lock` 里的三个新输入和 git 状态一致）。
2. 删掉会遮住 store 配置的东西 —— `~/.config/quickshell/clavis` 必须在 XDG
   回退之前不存在：

   ```bash
   rm -rf ~/.config/quickshell/clavis ~/.config/inir ~/.local/state/quickshell/inir
   systemctl --user disable --now inir.service 2>/dev/null
   ```

3. iNiR 时代的生成物可以清掉（Clavis 会自己重建）：

   ```bash
   rm -rf ~/.config/foot/colors.ini ~/.config/fuzzel/fuzzel_theme.ini \
     ~/.config/wallpaper-tones.txt
   ```

4. Clavis 的 `~/.config/clavis/**` 是新的：首次启动自己生成，之后在
   `Mod+Comma`（设置中心）里把壁纸目录指到 `~/Pictures/Wallpapers`。
