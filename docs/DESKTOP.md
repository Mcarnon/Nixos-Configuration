# Desktop (niri + Clavis Shell) 维护手册

> 2026-09 迁移记录：桌面壳回到 **Clavis Shell**（`StatIndet/quickshell` 当前
> HEAD，C++/Qt6 QML + Quickshell），配套 `key` 命令来自 `StatIndet/key-cli`。
> 中间经过 Noctalia v5，现已完全移除。SHORiN 风格靠三处保留：niri 的静态
> 配色（`home/niri/clavis-static.kdl`）、全量静态键位（`home/niri/binds.kdl`）、
> 以及 NyxNiri 壁纸选择器。登录仍是 ly，niri 合成器不变。

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/ly.nix` | 登录界面（ly，TUI 显示管理器） |
| `modules/nixos/desktop/niri.nix` | niri 会话 wrapper（关键：激活 graphical-session.target）+ `key`/字体 + 键盘 LED udev 规则 + 可选 RAPL setcap + polkit + fcitx5 服务 + xdg portal 路由 |
| `home/niri/config.kdl` | niri 主配置（环境变量/光标/输入/布局/动画 + Clavis 托管片段 include） |
| `home/niri/binds.kdl` | 全部快捷键（`key ipc call` + 音量/媒体/窗口/工作区） |
| `home/niri/blur.kdl` | 全局 blur 参数（只剩 `blur{}` 参数块）。自加的全局 `opacity` / `background-effect` 规则已删 |
| `home/niri/windowrule.kdl` | 只剩 Clavis 三条面板规则（主控 60%×85% 浮动、子对话框/文件选择器圆角）。逐应用透明度/悬浮/中文应用/PiP/快速终端规则**已按「照抄上游」删除** |
| `home/niri/supertab.kdl` | 带缩略图的 Alt/Ctrl+Tab 窗口切换 |
| `home/niri/startup.kdl` | 启动项（Wayland 环境导入 / xwayland-satellite / nm-applet） |
| `home/niri/clavis-static.kdl` | SHORiN niri 配色。**唯一**的 niri 强调色来源（Clavis 不再生成 colors 片段） |
| `hosts/laptop/niri-hardware.kdl` | 本机显示器输出 |
| `modules/home/desktop/niri.nix` | 把上面的 `.kdl` 软链到 `~/.config/niri` |
| `modules/home/desktop/clavis/default.nix` | Clavis 集成：`clavis-shell`/`clavis-clipboard` 用户服务、种子配置、壁纸选择器/轮换/tone 扫描、主题同步 |
| `modules/home/desktop/clavis/config.json` | 种子个性化配置（Clavis 启动后自己回写，HM 不再覆盖） |
| `modules/home/desktop/appearance.nix` | 光标 Breeze / GTK adw-gtk3-dark / 图标 Papirus / fcitx 桥接 / fontconfig |
| `modules/home/apps/gui.nix` | foot/thunar/nautilus/imv/satty + Thunar 配置 |
| `pkgs/clavis-shell/default.nix` | Clavis 本体（native QML 模块 + QML 源树 + matugen 模板 + systemd unit） |
| `pkgs/key-cli/default.nix` | `key` 命令 + `key-sysmon` + `key-cpu-power`，以及 QML/plugin 运行时环境 |
| `pkgs/m3shapes/default.nix` | `import M3Shapes` 所需的 QML 模块 |

## 启动链路

`ly (tty1)` → 选 niri 会话 → `niri-session-wrapper`（激活
`graphical-session.target`）→ niri.service → 拉起 clavis-shell /
clavis-clipboard / polkit / fcitx5 用户服务；`startup.kdl` 再起
xwayland-satellite、nm-applet。

`clavis-shell.service` 挂 `PartOf/Requisite=niri.service`，所以 niri 停它跟着停；
`StartLimitIntervalSec=0` + `Restart=always` 避免崩溃循环变成永久 failed（那正是
黑屏且不自愈的形态）。`clavis-session-env` 负责等 Wayland socket 出现再 exec
`key shell --foreground --no-duplicate`。

## niri 托管片段

Clavis 的 `scripts/system/niri_config.py` 会写这六个文件到
`~/.config/niri/clavis/`：

`effects`、`cursor`、`layer-rules`、`binds`、`outputs`、`minimize-animation`

这六个片段里只有两个和「窗口/图层规则」有关，也就是上游窗口配置的全部内容：
`effects`（X-Ray 开启时只有一行注释；关掉 X-Ray 才写 `^clavis-shell-` 命名空间和
`clavis-control-center(-*)` / `clavis-file-picker` 两个 title 的
`background-effect { xray false }`）和 `layer-rules`（overview 壁纸
`place-within-backdrop` + `layout { background-color "transparent" }`）。
其余窗口规则——逐应用透明度/悬浮、写死尺寸、中文应用、PiP、快速终端、全局
`geometry-corner-radius`、通知排除录屏、`debug { honor-xdg-activation-with-invalid-serial }`
——都是本仓库自加的，已按「照抄上游」删除。
`home/niri/windowrule.kdl` 现在只留作者截图里能直接看到的 Clavis 面板浮动与圆角三条。

`home/niri/config.kdl` 必须**提前**用 `include optional=true` 写好这六行，否则
Clavis 会把它们标成 `not-connected`；而它自己的 "Set up" 会去 append
`config.kdl` —— 那是指向 /nix/store 的只读软链，append 要么失败要么把声明式
文件变成普通文件。`optional=true` 同时保证 Clavis 还没跑起来时 niri 也能启动。

`clavis/binds.kdl` 故意 include 在本仓库 `binds.kdl` **之前**：两边在
`Mod+Space`/`Mod+Slash`/`Mod+Shift+Space`/`Mod+N`/`Mod+A`/`Mod+Shift+T` 上绑的
是同一个动作，所以 niri 解析重复键位时谁先谁后都一样。

## 常用键位（完整版见 `Mod+Shift+Slash` 键位教程）

| 键 | 功能 |
|---|---|
| `Mod+Space` | Spotlight 启动器（`key ipc call spotlight toggle`） |
| `Mod+S` / `Mod+Comma` | 控制中心 toggle / open（页面参数 `general`） |
| `Mod+N` / `Mod+A` | 信息侧栏 / 快捷设置侧栏 |
| `Mod+Shift+Space` | Spotlight 网页搜索 |
| `Mod+W` | NyxNiri 壁纸选择器（GTK3） |
| `Mod+V` | 剪贴板历史（`spotlight openMode clipboard`） |
| `Mod+F2` / `Mod+Shift+B` / `Mod+Shift+T` | Keystone hub / dashboard / tools |
| `Mod+Slash` | 快捷键配置图（`shortcut-map toggle`） |
| `Mod+Return` | foot 终端 |
| `Mod+Period` | foot 快速终端（quickterminal class） |
| `Mod+E` | thunar/nautilus 文件管理器 |
| `Mod+B` | zen-beta 浏览器 |
| `Alt+Tab` | niri 窗口总览切换 |
| `Print` / `Ctrl+Print` / `Alt+Print` | 区域 / 全屏 / 窗口截图 |
| `Mod+Shift+S` | satty 编辑最后截图 |
| `Mod+F10` | 随机壁纸（`key ipc call wallpaper random`） |
| `Mod+Shift+F10` | 下载随机动漫壁纸并应用 |
| `Super+Alt+L` | Clavis 锁屏（`key ipc call lock open`） |
| `Mod+Alt+P` | 锁屏 + 挂起 |

## 常见操作

- 改键位 → `home/niri/binds.kdl`（`Mod+Shift+Slash` 查当前生效键位）。
  改了之后 `nixos-rebuild switch` + `niri msg action quit` 重进会话；
  niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件。
- 改 Clavis 外观/壁纸 → Clavis 设置中心（控制中心 → 设置），GUI 写
  `~/.config/clavis/config.json`；声明式种子在
  `modules/home/desktop/clavis/config.json`（只在文件不存在时种一次，之后
  GUI 改动优先 —— 这是刻意的，见模块内 `seedFile` 注释）。
- Clavis 重启 → `systemctl --user restart clavis-shell`。
- 换壁纸目录 → 图放 `~/Pictures/Wallpapers/`。
- 随机动漫壁纸 → `random-anime-wallpaper-clavis`（下载到
  `~/Pictures/Wallpapers/api-random-download`）。
- 诊断 → `key doctor`（逐项检查 qs/qalc/gio/录屏/剪贴板/音频等后端）。

## 主题链路

Clavis 改壁纸或主题模式后跑自己的 matugen（`matugen/config.toml`），
只写五个目标：`clavis/colors.json`、btop、cava、`kitty/themes/Matugen.conf`、
yazi。kitty 的 post_hook 还会把它 `cp` 成 `kitty/current-theme.conf` 再
`pkill -USR1 -x kitty` —— 所以这两个文件都是**可写普通文件**，由
`clavis` 模块用 activation 种（不能做成 store 软链）。

GTK 深/浅色不在 matugen 覆盖范围内，由
`modules/home/desktop/clavis/bin/clavis-theme-sync` 写
`org.gnome.desktop.interface color-scheme`（依赖 NixOS 侧的
`gsettings-desktop-schemas`，否则 dconf 静默失败）。触发点有两个：
`clavis-config.path` 盯 `config.json`，`clavis-kitty-theme.path` 盯 matugen
产物落地。

Clavis 的 matugen 模板**不含** GTK、fuzzel、foot、niri —— 这几个仍是本仓库
声明式管理的（`appearance.nix` / `home/files/fuzzel.ini` /
`home/files/foot.ini` / `home/niri/clavis-static.kdl`）。

## 已知取舍

- Clavis 与 key-cli 来自 `flake = false` 的源码输入（`StatIndet/quickshell`、
  `StatIndet/key-cli`），没有二进制缓存，首次构建较久；升级 =
  `nix flake update clavis-shell key-cli m3shapes`。
- `pkgs.keyCli` 的 wrapper 是整套集成里最脆的一环：它把 Clavis、Quickshell、
  M3Shapes、MapLibre 和各 Qt 模块的 QML 根与 plugin 目录拼成
  `QML_IMPORT_PATH`/`QT_PLUGIN_PATH`。路径错了不会编译失败，只会登录后黑屏，
  所以 derivation 里对四个必需 QML 模块逐个校验 `qmldir` 存在。
  注意 Clavis 的模块装在 `lib/qt6/qml`（上游 CMake 的
  `CLAVIS_QML_INSTALL_DIR`），和 nixpkgs 的 `lib/qt-6/qml` 不是同一个前缀。
- 键盘背光需要 `modules/nixos/desktop/niri.nix` 里的 udev 规则
  （只给带 LED 能力的键盘打 `uaccess`），否则 `key doctor` 报键盘不可用。
- CPU 功率读数（RAPL）需要 `clavis-key-cpu-power-access` 这个 root oneshot
  给 `key-cpu-power` 加 `cap_dac_read_search`；失败不影响 CPU 占用率，只是
  功率那一项显示 unavailable。
- 锁屏是 Clavis 自带；休眠组合 `Mod+Alt+P` 会锁屏后挂起。
- 通知由 Clavis 接管。但「把 notification 命名空间排除出录屏」那条 `layer-rule`
  是本仓库自加的，已按「照抄上游」删除 —— 副作用是录屏/共享屏幕时通知会入镜。
  想要回来，在 `home/niri/windowrule.kdl` 末尾加：
  `layer-rule { match namespace="^notification$"; block-out-from "screencast"; }`。
- 逐应用窗口规则（spotify / pavucontrol / thunar 的浮窗尺寸、`Mod+Period` 快速
  终端下拉、画中画、中文应用弹窗、brave 不透明、全局 `geometry-corner-radius 23`、
  `debug { honor-xdg-activation-with-invalid-serial }`）都是自加的，已按「照抄上游」
  删除。副作用：普通应用窗口回到 niri 默认的方角 + 不透明，快速终端变成按 0.5 列宽
  平铺。要整体回退：`git show f0358ac:home/niri/windowrule.kdl > home/niri/windowrule.kdl`。
- 旧 `modules/home/desktop/dynamic-wallpaper.nix`（mpvpaper 时代的壁纸轮换，依赖
  Noctalia 的 `noctalia msg`）已删除；壁纸轮换现在由 Clavis 的
  `wallpapers-rotate.py`（挂 Matugen post-hook）承担。
