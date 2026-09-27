# Desktop (niri + iNiR) 维护手册

> 2026-09 迁移记录：桌面壳由 Clavis Shell 切到 **iNiR**
> （`github:snowarch/iNiR`，同样是 Quickshell 外壳，但自带 flake + NixOS/Home
> Manager 模块，IPC 统一走 `inir <target> <function>`）。本仓库不再自建打包、
> 壁纸脚本、主题同步：这些 iNiR 都自带。登录仍是 ly，niri 合成器不变
> （`niri.service` 拉起，外壳挂在它下面）。

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/ly.nix` | 登录界面（ly，TUI 显示管理器） |
| `modules/nixos/desktop/niri.nix` | niri 会话 wrapper（关键：激活 graphical-session.target）+ polkit + fcitx5 服务 + xdg portal 路由 + 快捷键/脚本要用的外部命令进系统 PATH |
| `home/niri/config.kdl` | niri 主配置（环境变量/光标/输入/布局/动画 + include `inir-static.kdl`） |
| `home/niri/binds.kdl` | 全部快捷键（`inir` IPC + 音量/媒体/窗口） |
| `home/niri/blur.kdl` | 全局毛玻璃基线（blur + 窗口透明度） |
| `home/niri/windowrule.kdl` | 逐应用透明度/悬浮/中文应用规则 + layer 规则（iNiR 壁纸层 `quickshell:iiBackground`） |
| `home/niri/startup.kdl` | 启动项（环境导入 / `inir` watchdog / xwayland-satellite / nm-applet） |
| `home/niri/inir-static.kdl` | SHORiN 默认 niri 配色（纯静态；iNiR 不改 niri 配色） |
| `hosts/laptop/niri-hardware.kdl` | 本机显示器输出 |
| `modules/home/desktop/inir/default.nix` | iNiR：导入上游 `homeManagerModules`、服务加固（`inir-session-env` 包装 + 不限速）、`extraPackages`、配置/主题种子、默认壁纸 |
| `modules/home/desktop/inir/bin/inir-session-env` | 启动包装：最多等 ~20s 出现 `wayland-N` socket 再 exec（黑屏修复的第二道保险） |
| `modules/home/desktop/appearance.nix` | 光标 breeze 24 / GTK adw-gtk3-dark / 图标 Papirus / fcitx 桥接 / fontconfig（深浅色初值，之后由 iNiR 接管） |
| `modules/home/apps/gui.nix` | foot/thunar/nautilus/imv/satty + kitty.conf（include iNiR 生成的 `themes/current-theme.conf`） |
| `checks/niri-config.nix` | flake check：跑 `niri validate`，并断言没有把已删除的 `key ipc` 抄回来 |

## 启动链路

`ly (tty1)` → 选 niri 会话 → `niri-session-wrapper`（激活
`graphical-session.target`）→ `niri.service` → 按 `WantedBy=niri.service` 拉起
`inir.service`（上游模块自带 `PartOf/Requisite/After=niri.service`）；
`startup.kdl` 再起 xwayland-satellite、nm-applet，并跑一个 watchdog：30s 后若
`inir.service` 不是 active 就 `systemctl --user restart inir`。

三道黑屏保险：`startup.kdl` 里的 `import-environment` → `inir-session-env`
等 socket → 服务 `Restart=on-failure` + 我们把 `StartLimitIntervalSec` 覆盖成
`0`（不会变成永久 failed）。

## iNiR 侧的三件事（都走上游，别自己造）

1. **服务**：`systemd.user.services.inir`，`Type=dbus` +
   `BusName=org.kde.StatusNotifierWatcher`（托盘归它，所以别再启别的 StatusNotifier
   消费者）。`ExecStart` 被我们换成
   `inir-session-env ${inir} run --session`。
2. **配置**：`~/.config/inir/config.json`。本仓库用 `home.activation` 种一次
   「上游 defaults + `appearance.wallpaperTheming.terminals.starship=false`」
   （`modules/home/desktop/inir/default.nix` 里的 `inirConfigSeed`），
   之后用户在设置界面里的改动永远不会被 switch 覆盖。关掉 starship 是因为
   我们的 `starship.toml` 由 home-manager 声明式管理（只读 store 软链），
   iNiR 的 starship 模板会试图往里追加 `format`。
3. **生成物**（不要手改，会被重写）：
   - `~/.local/state/quickshell/user/generated/`：material 配色、各终端/编辑器主题
   - `~/.config/kitty/themes/current-theme.conf`、`~/.config/foot/colors.ini`、
     `~/.config/fuzzel/fuzzel_theme.ini`、`~/.config/{btop,yazi,lazygit}/`
   - 终端/GTK 的深浅色还会通过 OSC 序列直接注入正在运行的 pts

   `kitty.conf` / `foot.ini` / `fuzzel.ini` 里的 `include` 行**必须提前写好**
   （本仓库已经写好）：iNiR 生成完会检查这些文件里有没有那行，没有就追加 ——
   而它们是指向 `/nix/store` 的只读软链，追加只会失败并记一条日志。

## 常用键位（完整版见 `Mod+Shift+Slash` 键位教程 / `inir cheatsheet toggle`）

| 键 | 功能 |
|---|---|
| `Mod+Space` | Overview / 启动器（`inir overview toggle`） |
| `Mod+S` / `Mod+Comma` | 快捷面板 toggle / 设置（`inir controlPanel toggle` / `inir settings open`） |
| `Mod+F2` | 仪表盘：媒体/天气/日历（`inir dashboard toggle`） |
| `Mod+Shift+B` | 命令面板（`inir globalActions open`） |
| `Mod+W` | 壁纸选择器（`inir wallpaperSelector toggle`） |
| `Mod+V` | 剪贴板历史（`inir clipboard toggle`） |
| `Mod+Return` | foot 终端 |
| `Mod+E` | nautilus 文件管理器 |
| `Mod+B` | zen-beta 浏览器 |
| `Alt+Tab` | niri 窗口总览切换（`supertab.kdl` 的带缩略图切换） |
| `Print` / `Ctrl+Print` / `Alt+Print` | 区域 / 全屏 / 窗口截图 |
| `Mod+Shift+S` | satty 编辑最后截图 |
| `Mod+F10` | 随机壁纸（`inir wallpaperSelector random`） |
| `Mod+Shift+F10` | 在线动漫壁纸（`inir wallpaperSelector browse live -`） |
| `Super+Alt+L` | 锁屏（`inir lock activate`） |
| `Mod+Alt+P` | 关显示器 + 锁屏 + 挂起 |

其它 iNiR 自带但没绑键的（想要就自己加一行 `inir <target> <function>`）：
`session toggle`（电源菜单）、`cheatsheet toggle`、`pill toggle <surface>`、
`bar toggle`、`region ocr` / `region search`、`osd volume`、`mascot poke`。

## 常见操作

- 改键位 → `home/niri/binds.kdl`（`Mod+Shift+Slash` 可查当前生效键位）。
  改完跑一次 `nix flake check`（`checks/niri-config.nix` 会替你跑 `niri validate`）。
  全部可用 IPC target：`inir help`。
- 改 niri → `nixos-rebuild switch` 后 `niri msg action quit` 重进会话。
  注意：niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件。
- 改 iNiR 外观/壁纸 → `inir settings open`（或 `Mod+Comma`）。设置写入
  `~/.config/inir/config.json`，是运行时唯一事实来源；仓库里的种子**只在文件
  不存在时**种一次，所以 GUI 改动不会被 switch 覆盖。
- 重启外壳 → `systemctl --user restart inir.service`（应急手段：`inir memory restart`）。
- 换壁纸目录 → 图放 `~/Pictures/Wallpapers/`，在设置里改目录。
- 换壁纸后终端/GTK 配色不更新 → 看
  `~/.local/state/quickshell/user/generated/terminal_colors.log`，多半是某个
  终端的 `appearance.wallpaperTheming.terminals.<term>` 被关了，或者对应程序
  没装（生成器只写装了的终端）。

## 已知取舍

- iNiR 的包由上游 flake 提供，但**用本 flake 的 nixpkgs 构建**
  （`programs.inir.package` 默认值 = `pkgs.callPackage <inir>/nix/package.nix`）。
  万一上游依赖的 python 包在本机 nixpkgs 缺失，逃生口是显式写
  `programs.inir.package = inputs.inir.packages.${pkgs.stdenv.hostPlatform.system}.inir`
  （那就用上游 pin 的 nixpkgs 构建）。
- **壁纸取色不再覆盖 niri 配色**（`inir-static.kdl` 是最终值）：iNiR 只重画自己
  的层 + 自己的模板，不注入 niri 的 focus-ring/urgent 色。
- 壁纸轮换（每半小时）+ 色调库（每天 03:20 的 `scan-tones`）已随 Clavis 一起
  删除：iNiR 的 wallpaper selector 里有 grid/coverflow/launcher 三种样式和
  `random`，在线动漫壁纸走 `browse live`。
- `keytop`（独立系统监视 TUI）已删除：iNiR 自带系统监视（设置里的模块开关）。
- 窗口切换仍然交给 niri（`Alt+Tab` → overview / `supertab.kdl`），没用 iNiR 的
  `altSwitcher` / `orbit`：合成器侧的切换在 XWayland 窗口和多工作区下更稳。
- 通知由 iNiR 接管（状态栏的通知中心 + iNiR 自己的提示层）。
