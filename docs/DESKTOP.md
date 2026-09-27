# Desktop (niri + Clavis) 维护手册

> 2026-09 迁移记录：桌面壳由 iNiR 切回 **Clavis Shell**
> （`github:StatIndet/quickshell`，Quickshell 外壳）**+ `key-cli`**
> （`github:StatIndet/key-cli`）+ M3Shapes（`github:soramanew/m3shapes`）。
> 三个上游都没给 NixOS/Home Manager 模块（key-cli 只有 Python 包），所以本仓库
> 自己打包、自己接线，登录仍是 ly，niri 合成器不变（`niri.service` 拉起，
> 外壳挂在它下面）。

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/ly.nix` | 登录界面（ly，TUI 显示管理器） |
| `modules/nixos/desktop/niri.nix` | niri 会话 wrapper（关键：激活 graphical-session.target）+ polkit + fcitx5 + `services.udev.packages = [ pkgs.keyCli ]`（键盘 LED 授权）+ xdg portal 路由 + 字体 + 快捷键/脚本要用的外部命令进系统 PATH |
| `home/niri/config.kdl` | niri 主配置（环境变量/光标/输入/布局/动画 + include `clavis-static.kdl` + `include optional=true "clavis/effects.kdl"`） |
| `home/niri/binds.kdl` | 全部快捷键（Clavis 走 `key ipc call`，音量/媒体/窗口走原生动作） |
| `home/niri/blur.kdl` | 全局毛玻璃基线（blur + 窗口透明度） |
| `home/niri/windowrule.kdl` | 逐应用透明度/悬浮/中文应用规则 + layer 规则（Clavis 壁纸层 `clavis-wallpaper`） |
| `home/niri/startup.kdl` | 启动项（环境导入 / `clavis-shell.service` watchdog / xwayland-satellite / nm-applet） |
| `home/niri/clavis-static.kdl` | SHORiN 默认 niri 配色（纯静态；Clavis 不改 niri 配色） |
| `hosts/laptop/niri-hardware.kdl` | 本机显示器输出 |
| `pkgs/clavis-shell/default.nix` | Clavis 本体：原生 `Clavis.*` QML 插件 + QML 树装到 `$out/etc/xdg/quickshell/clavis` + 上游 systemd unit（声明式配置里不用它） |
| `pkgs/key-cli/default.nix` | `key` 命令 + `key-sysmon`/`key-cpu-power` + **运行时 wrapper**（PATH / QML_IMPORT_PATH / XDG_CONFIG_DIRS 钉死） |
| `modules/home/desktop/clavis/default.nix` | 会话接线：两个 systemd user unit、Qt/fcitx 环境、qt6ct + kitty 主题的可写种子、默认壁纸 |
| `modules/home/desktop/clavis/bin/clavis-session-env` | 启动包装：最多等 ~20s 出现 `wayland-N` socket 再 exec（黑屏修复的第二道保险） |
| `modules/home/desktop/appearance.nix` | 光标 breeze 24 / GTK adw-gtk3-dark / 图标 Papirus / fcitx 桥接 / fontconfig |
| `modules/home/apps/gui.nix` | foot/thunar/nautilus/imv/satty + kitty.conf（include Clavis matugen 写的 `current-theme.conf`） |
| `checks/niri-config.nix` | flake check：跑 `niri validate`，断言外壳调用方式是 `key ipc call`、effects 片段是 optional、关键环境变量非空 |

## 启动链路

`ly (tty1)` → 选 niri 会话 → `niri-session-wrapper`（激活
`graphical-session.target`）→ `niri.service` → 按 `WantedBy=niri.service` 拉起
`clavis-shell.service`（`ExecStart = clavis-session-env key shell
--foreground --no-duplicate`，`key shell` = `qs -c clavis -n`）和
`clavis-clipboard.service`（`key clipboard watch`）；
`startup.kdl` 再起 xwayland-satellite、nm-applet，并跑一个 watchdog：30s 后若
`clavis-shell.service` 不是 active 就 `systemctl --user restart`。

三道黑屏保险：`startup.kdl` 里的 `import-environment` → `clavis-session-env`
等 socket → 服务 `Restart=on-failure` + 我们把 `StartLimitIntervalSec` 覆盖成
`0`（不会变成永久 failed）。

## 为什么 `key` 必须包一层 wrapper

`key` 不是普通 CLI：

- `key shell` 只是 `exec qs -c clavis -n`，所以 PATH 里必须有 quickshell；
- QML 树的 import 根不是 Qt 默认值。nixpkgs 的 Qt6 装在
  `lib/qt-6/qml`（`qtbase.qtbase.qtQmlPrefix`），写错目录的后果是
  quickshell 起来之后在加载 QML 时才炸
  （`module "Qt5Compat.GraphicalEffects" is not installed`）——黑屏且日志里
  找不到有用信息；
- Quickshell 解析 `qs -c clavis` 时**先看 `~/.config/quickshell/clavis`**，
  不存在才回退 `XDG_CONFIG_DIRS/quickshell/clavis`。我们的配置在只读
  store 里，所以 wrapper 必须 `XDG_CONFIG_DIRS=$clavisShell/etc/xdg`；
- `key file`/`key sysmon`/`key record`/`key clipboard` 会 shell out 到
  `fd`/`gio`/`busctl`/`xdg-terminal-exec`/`cliphist`/`wl-copy`/
  `gpu-screen-recorder`/`slurp`/`ffmpeg`/`pactl`/`matugen`/`hyprpicker` 等。

所以 `pkgs/key-cli` 生成一个手写 wrapper（不是 makeWrapper：QML_IMPORT_PATH 与
XDG_CONFIG_DIRS 必须**追加**到现有会话环境）。`home.packages` 里放的是这个
wrapper，niri 的 `spawn` 直连 PATH，因此 binds.kdl 只能写 `key ipc call ...`，
不能写裸 `qs`/`quickshell ipc`（会话 PATH 里没有 qs）——`checks/niri-config.nix`
会拦这个。

## 声明式 / 运行时的分界

仓库管（只读 store 软链）：

- `$out/etc/xdg/quickshell/clavis/**`（QML 树 + assets + scripts + matugen 配置）
- `home/niri/*.kdl`、`~/.config/kitty/kitty.conf`、`~/.config/foot/foot.ini`

仓库不管（外壳自己写，`switch` 不会动）：

- `~/.config/clavis/**`、`~/.local/state/clavis/**`、`~/.local/state/quickshell/**`
- `~/.config/niri/clavis/effects.kdl`（模糊/xray 开关；主配置用
  `include optional=true` 引入 —— 硬 include 会让第一次开机直接失败）
- `~/.config/kitty/themes/Matugen.conf` → `cp` 到
  `~/.config/kitty/current-theme.conf`

`modules/home/desktop/clavis` 只种两份**可写**副本（`home.activation`，
`[ ! -e ]` 才动手，switch 永不覆盖）：

- `~/.config/qt6ct/qt6ct.conf`（Qt6 应用图标主题/样式，GUI 会回写）
- `~/.config/kitty/current-theme.conf`（matugen post_hook 的落点，必须可写）

**不要**创建 `~/.config/quickshell/clavis`：它在 XDG 回退之前，存在就会遮住
store 里的配置（以前从源码跑外壳时留下的软链要删掉）。

## 常用键位（完整列表见 `Mod+Shift+Slash` 的键位教程）

| 键 | 功能 |
|---|---|
| `Mod+Space` | Spotlight（搜索/应用/网页/文件） |
| `Mod+Shift+Space` | Spotlight 网页搜索 |
| `Mod+Alt+V` | 剪贴板历史 |
| `Mod+Alt+W` | 壁纸 |
| `Mod+N` | 信息侧栏：通知/天气/日历/小工具 |
| `Mod+A` | 快捷设置侧栏：音量/亮度/蓝牙 |
| `Mod+Comma` | 设置中心 |
| `Mod+Shift+W` | Keystone 主面板 |
| `Mod+Shift+T` | 工具面板（录屏/录音/截图） |
| `Mod+Shift+B` | 命令面板（`/calc`、`/fx`、`/time`…） |
| `Super+Alt+L` | 锁屏 |
| `Mod+Return` | foot 终端 |
| `Mod+E` | nautilus 文件管理器 |
| `Mod+B` | zen-beta 浏览器 |
| `Alt+Tab` | niri 窗口总览切换（`supertab.kdl` 的带缩略图切换） |
| `Print` / `Ctrl+Print` / `Alt+Print` | 区域 / 全屏 / 窗口截图 |
| `Mod+Shift+S` | satty 编辑最后截图 |
| `Mod+Alt+P` | 关显示器 + 锁屏 + 挂起 |
| `Mod+Slash` | 快速终端（kitty→foot 回退；不是 Clavis 的 shortcut-map） |

没绑键但可用的动作（加一行 `key ipc call <target> <method>` 即可，或在
Clavis 设置 → 快捷键 里绑）：`shortcut-map toggle`、`keystone lyrics`、
`sidebar toggle weather` / `sidebar toggle drawer`、
`spotlight command <name>`（命令面板的全部动作）、`spotlight openMode files`。
完整目录：`key ipc show`；动作注册表在 `docs/ipc.md`（上游）。

## 常见操作

- 改键位 → `home/niri/binds.kdl`（`Mod+Shift+Slash` 可查当前生效键位）。
  改完跑一次 `nix flake check`（`checks/niri-config.nix` 会替你跑 `niri validate`）。
- 改 niri → `nixos-rebuild switch` 后 `niri msg action quit` 重进会话。
  注意：niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件。
- 改 Clavis 外观/壁纸 → `Mod+Comma`（设置中心）或 Spotlight（`/` 开命令面板：
  `/settings`、`/light`、`/dark`）。设置写在 `~/.config/clavis/**`，是运行时
  唯一事实来源，仓库不接管。
- 换壁纸目录 → 图放 `~/Pictures/Wallpapers/`，在 设置 → 个性化 里改目录。
- 重启外壳 → `systemctl --user restart clavis-shell.service`；
  应急杀掉重起 → `key shell --kill && key shell`。
- 剪贴板不记录 → `key clipboard status --format json` 看 `watcherRunning`；
  先确认 `systemctl --user is-active niri.service`（watcher 需要活跃的 niri）。
- 键盘 Caps/Num Lock 的 OSD 不亮 → udev 规则来自
  `services.udev.packages = [ pkgs.keyCli ]`（给 evdev 键盘节点加 ACL），
  Clavis 设置 → Keystone 里还要打开对应开关；`key keyboard status --format json`
  看设备权限。
- 换壁纸后 kitty 不变色 → Clavis 的 matugen 只写它那 5 个模板（btop/cava/
  kitty/yazi/quickshell-colors），foot/fuzzel/starship/GTK **不会**被取色覆盖，
  这不是故障。

## 已知取舍

- **三个上游都没 flake 集成**：`clavis-shell`/`key-cli` 以 `flake = false` 源码
  输入，由本仓库 `pkgs/{clavis-shell,key-cli}` 编译；M3Shapes 有自己的 flake，
  但它的 nixpkgs `follows` 本 flake 的 nixpkgs，避免同一台机器两套 Qt。
  版本号在两个 derivation 里写死（不是 `git describe`）：升级要手改
  `version`。
- **MapLibre 天气地图不打包**：`pkgs/key-cli` 的 `QML_IMPORT_PATH` 里刻意没有
  `maplibre-native-qt`（它会把 QtLocation + MapLibre C++ 核心全拖进闭包，而天气
  地图没人天天开）。QML 里 import 不到 `MapLibreNative` 时会退到
  `Modules/Map/MapFallback.qml`，不会拖垮外壳。
- **quickshell 版本比上游验证基线低一格**：本 flake 锁的 nixpkgs 里 quickshell 是
  0.3.0，上游 `packaging/dependencies.json` 标的验证基线是 0.3.1。跑起来没问题，
  但看到 QML 层的诡异行为时先 `nix flake update nixpkgs` 排除版本因素。
- **niri 片段要 26.4**（只有 effects 那一片）：本 flake 锁的 nixpkgs 里 niri 是
  26.04，够用。Clavis 会管 `~/.config/niri/clavis/` 下六个片段（effects / cursor /
  layer-rules / binds / outputs / minimize-animation），但它的 "Set up" 要往
  `config.kdl` 里写 include —— 我们的 config.kdl 是 store 软链、只读，所以
  `home/niri/config.kdl` 已经手动 `include optional=true` 了，缺失的文件由
  Clavis 自己创建，不用点 Set up。
- **壁纸取色不覆盖 niri 配色**（`clavis-static.kdl` 是最终值），也不覆盖
  GTK/starship/foot。
- 壁纸轮换（每半小时）+ `scan-tones` 色调库 + iNiR 的 `wallpaperSelector`
  `random`/`browse live` 都不存在了：Clavis 没有对应的 IPC/CLI 入口，壁纸只在
  Spotlight 的 wallpapers 模式里选。
- `key-cpu-power`（RAPL 能耗读取）默认没有额外 capabilities：系统监视里少了
  功耗读数，其它指标正常。想要就显式给 `security.papermi` 加
  `readcap = [ "cap_sys_admin" ]`（上游文档警告过它能读到别的进程的能耗数据）。
- 窗口切换仍然交给 niri（`Alt+Tab` → overview / `supertab.kdl`），不用 Clavis 的
  altSwitcher：合成器侧的切换在 XWayland 窗口和多工作区下更稳。
- 通知由 Clavis 接管（信息侧栏的通知中心 + 它自己的 OSD 层）。
