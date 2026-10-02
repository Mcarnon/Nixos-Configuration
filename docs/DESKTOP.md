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
| `home/niri/config.kdl` | niri 主配置（环境变量/光标/输入/布局/动画 + Clavis 托管片段 include）。⚠️ 运行时那份 `~/.config/niri/config.kdl` 是可写副本，不是 store 软链 |
| `home/niri/binds.kdl` | 全部快捷键（`key ipc call` + 音量/媒体/窗口/工作区） |
| `home/niri/blur.kdl` | `blur{}` 参数块 + **全局窗口半透明 + 背景模糊**（`opacity 0.9`，未聚焦 0.85，`background-effect { blur true }`）。默认走 niri 自动开的 xray（省、动画不掉模糊）；想要「真·玻璃」把里面 `xray false` 那行注释放开 |
| `home/niri/windowrule.kdl` | 全局圆角 23 + Clavis 面板浮窗（主控 60%×85%，圆角 23/28/30，opacity 1.0 以免叠上全局 0.9）+ 快速终端下拉 + 其它应用浮窗尺寸（920×600 / 620×640 / 1100×750，取自 Clavis 源码窗口定义）+ 图片/视频/PiP/Blender 强制不透明无模糊（Blender 是上色/渲染需要真实颜色）+ 中文应用弹窗 + 通知排除录屏 + **backdrop 兜底规则**（概览/切工作区时壁纸后面那层背景） |
| `home/niri/supertab.kdl` | 带缩略图的 Alt/Ctrl+Tab 窗口切换 |
| `home/niri/startup.kdl` | 启动项（Wayland 环境导入 / xwayland-satellite / nm-applet） |
| `home/niri/clavis-static.kdl` | SHORiN niri 配色。**唯一**的 niri 强调色来源（Clavis 不再生成 colors 片段） |
| `hosts/laptop/niri-hardware.kdl` | 本机显示器输出 |
| `modules/home/desktop/niri.nix` | 把上面的 `.kdl` 软链到 `~/.config/niri`；**唯一例外**：`config.kdl` 刷成可写副本（Clavis 的 niri_config.py 拒绝软链，见「已知取舍 → Clavis 的 niri 集成」） |
| `modules/home/desktop/clavis/default.nix` | Clavis 集成：`clavis-shell`/`clavis-clipboard` 用户服务、种子配置（config.json + `niri/clavis/{layer-rules,cursor}.kdl`）、壁纸选择器/轮换/tone 扫描、主题同步 |
| `modules/home/desktop/clavis/niri/layer-rules.kdl` | backdrop 规则的种子（与上游 `initial('layer-rules')` 逐字一致），种到 `~/.config/niri/clavis/`；决定概览/切工作区时那层背景 |
| `modules/home/desktop/clavis/niri/cursor.kdl` | 光标片段种子（`ready("cursor")` 的前提），Clavis 启动后会按 config.json 重新生成它 |
| `modules/home/desktop/clavis/config.json` | 种子个性化配置（Clavis 启动后自己回写，HM 不再覆盖） |
| `modules/home/desktop/appearance.nix` | 光标 Bibata-Modern-Ice（声明式默认，唯一来源）/ GTK adw-gtk3-dark / 图标 Papirus / fcitx 桥接 / fontconfig |
| `modules/home/desktop/clavis/bin/clavis-theme-sync` | 把 config.json 的深浅色 + **光标主题/尺寸**同步给 dconf/GTK/Kvantum/foot（Clavis 自己不管这些） |
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
其余窗口规则——大/小窗口宽度、浮窗尺寸、中文应用弹窗、PiP、快速终端、全局
`geometry-corner-radius`、通知排除录屏、`debug { honor-xdg-activation-with-invalid-serial }`
——上游一个都不写（作者本机那份没公开），是本仓库按作者演示图实测自己定的，
口径见下方「已知取舍 → 窗口规则」。

`home/niri/config.kdl` 必须**提前**用 `include optional=true` 写好这六行，否则
Clavis 会把它们标成 `not-connected`（它「缺 include 就追加」的那条路写的是运行时
那份副本，每次 switch 会被源文件覆盖，所以 include 只能写在源里）。`optional=true`
同时保证 Clavis 还没跑起来时 niri 也能启动。

片段由谁创建、什么时候创建，是这条链路最容易踩的地方：

- Clavis **只创建它已有的**：`setup` 只在点「Set up」时发生，启动/打开设置页都不会
  建文件；而 `update`（改设置、启动时自动同步光标）要求片段**已经存在**
  （`ready(feature)`）。所以「文件不存在」时设置页只剩一个点得动的 Set up 按钮。
- 本仓库因此把其中两个种成可写副本（`modules/home/desktop/clavis/niri/*.kdl`
  → `~/.config/niri/clavis/`，`seedFile`：仅当文件不存在或是软链时写一次）：
  `layer-rules`（backdrop）和 `cursor`（光标）。它们分别对应设置中心里
  「壁纸 → Overview integration / Enable background」和「主题 → 光标主题/尺寸」。
- backdrop 这条规则另外还有一份兜底：`home/niri/windowrule.kdl` 里的 `layer-rule`。
  所以即使种子文件被删、backdrop 也不会空 —— 那种情况下 Clavis 的 `status()` 仍报
  `overviewSatisfied=true`（它扫的是整条 include 链，不要求规则出自它自己的片段），
  设置页显示 "Overview is already configured outside Clavis" 而不是一个点不动的
  Set up。

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
  `~/.config/niri` 下的 `.kdl` 都是 store 软链，不能直接改 —— **唯一例外**是
  `config.kdl`：它是每次 switch 刷新的可写副本（Clavis 要求主配置可写，见「已知
  取舍」），运行时改它会在下次 switch 被覆盖，所以改动请写回
  `home/niri/config.kdl`。
- 改光标主题/尺寸（**四处声明式默认**，或直接用 GUI）：
  1. `modules/home/desktop/appearance.nix` 的 `cursorTheme`/`cursorSize`（→
     `home.pointerCursor` + dconf，GTK3/GTK4/libadwaita + `~/.icons/default`）；
  2. `home/niri/config.kdl` 的 `cursor {}`（→ niri 自己画的光标 + 它派生给子进程的
     `XCURSOR_THEME`/`XCURSOR_SIZE`；那里刻意不写死 `XCURSOR_*`）；
  3. `home/files/xsettingsd.conf` 的 `Gtk/CursorThemeName`（走 XSETTINGS 的老应用）；
  4. `modules/home/desktop/clavis/niri/cursor.kdl`（种进 niri 的光标片段，
     只在新机器上生效一次，Clavis 随后会按 dconf 重新生成它）。
  `checks/niri-config.nix` 会校验 2/3/4 同名（1 是 Nix 属性，解析不了，靠人看）。
  想临时换、不想 rebuild：Clavis 设置中心 → 主题 → 光标主题（写入
  `~/.config/niri/clavis/cursor.kdl` + niri 重载配置），
  `clavis-theme-sync` 会把同一个值同步给 dconf。
- 改 Clavis 外观/壁纸 → Clavis 设置中心（控制中心 → 设置），GUI 写
  `~/.config/clavis/config.json`；声明式种子在
  `modules/home/desktop/clavis/config.json`（只在文件不存在时种一次，之后
  GUI 改动优先 —— 这是刻意的，见模块内 `seedFile` 注释）。
- 概览（`Alt+Tab` / `Mod+O`）或切换工作区时背景不是壁纸 → 说明 backdrop 规则没生效：
  确认 `~/.config/niri/clavis/layer-rules.kdl` 存在（`home-manager switch` 会种，
  删了就重跑一次）**或** `home/niri/windowrule.kdl` 里那条
  `place-within-backdrop` 还在；再看 `niri msg layers` 里有没有
  `clavis-overview-wallpaper`（没有就是 Clavis 侧 `wallpaper.overview.enabled=false`，
  设置中心 → 壁纸 → "Enable background" 打开）。
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
`gsettings-desktop-schemas`，否则 dconf 静默失败）。同一个脚本现在还负责**光标**：
Clavis 只把 `theme.cursorTheme/cursorSize` 写进 niri（`clavis/cursor.kdl`），
GTK/Qt/X11 那一半没人管，脚本把同一个值补进 dconf 的 `cursor-theme`/`cursor-size`
（`cursorTheme` 为空 = 它界面上的 "System default" 时不动 dconf，那个值本来就是
`appearance.nix` 的 `home.pointerCursor` 写进去的，反过来写会两边互相覆盖）。
触发点：`clavis-config.path` 盯 `config.json`（`clavis-kitty-theme.path` 已随 kitty
退役删除）。脚本自带签名幂等，光标值也进了签名（v5），否则「只改光标不改深浅色」
会被幂等逻辑短路掉。

Clavis 的 matugen 模板**不含** GTK、fuzzel、foot、niri —— 这几个仍是本仓库
声明式管理的（`appearance.nix` / `home/files/fuzzel.ini` /
`home/files/foot.ini` / `home/niri/clavis-static.kdl`）。

## 已知取舍

- **Clavis 的 niri 集成要求主配置可写**，所以 `~/.config/niri/config.kdl` 是本仓库
  唯一不是 store 软链的 niri 配置文件（由 `modules/home/desktop/niri.nix` 在
  `linkGeneration` **之前**刷一份副本，内容仍是声明式的）。原因：
  `niri_config.py` 的 `safe_target()` 在写**任何**片段之前都会拒绝软链——
  `Symbolic links are read-only: /home/<user>/.config/niri/config.kdl`，
  连「include 已写好、只缺片段文件」的路径也过不去。以前是软链，于是
  **读全正常（设置页看起来是好的）、写全失败**：Overview integration 的 Set up、
  光标主题/尺寸、透明与模糊全都点不动，backdrop 和光标因此一直是默认值。
  代价：Clavis 追加到主配置里的 include 不会留存（每次 switch 覆盖），所以六个
  `clavis/*.kdl` 的 include 必须写在 `home/niri/config.kdl` 源文件里 ——
  `checks/niri-config.nix` 会守着这一条。
- **概览 / 切换工作区时壁纸后面那层背景 = niri 的 backdrop**：只有被
  `place-within-backdrop` 收进去的 background 层表面才会出现在那里。Clavis 侧的
  表面是 `Modules/Wallpaper/OverviewWallpaper.qml`（namespace
  `clavis-overview-wallpaper`，由设置里「壁纸 → Enable background」即
  `wallpaper.overview.enabled` 控制可见性），规则本仓库写了两份：
  `home/niri/windowrule.kdl` 的兜底 `layer-rule` + 种到
  `~/.config/niri/clavis/layer-rules.kdl` 的种子（上游 `initial('layer-rules')`
  逐字一致）。上游自己只写后面那份，且只在点 Set up 时生成 —— 所以「开箱就该有」
  这件事必须由本仓库保证（见上一条：Set up 在软链主配置上必失败）。
  没有它时概览里只剩 `overview.backdrop-color`（默认深灰），看起来就是
  「背景层不见了」。
- **光标**：参考实现不钉任何主题 —— Clavis 的 `theme.cursorTheme` 默认空字符串，
  含义是「系统默认」，运行时取 `gsettings get org.gnome.desktop.interface
  cursor-theme`；作者自己的 dotfiles 里也没有 `cursor{}`/`XCURSOR_THEME`。
  本仓库把系统默认选成 **Bibata-Modern-Ice**（Clavis 明确借鉴的
  end-4/dots-hyprland、caelestia-shell、DankMaterialShell 都用它，Material 风格和
  这套配色一致），并保证 niri / dconf(GTK) / XSETTINGS / XWayland 指向同一个名字。
  换主题 = `appearance.nix` 的 `cursorTheme` + `home/niri/config.kdl` 的 `cursor{}` +
  `home/files/xsettingsd.conf` + `clavis/niri/cursor.kdl` 四处（`checks/niri-config.nix`
  校验后三处），或直接在 Clavis 设置中心选
  （走 `clavis/cursor.kdl` + `clavis-theme-sync`，不需要 rebuild）。
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
- 通知由 Clavis 接管；`layer-rule` 里把 notification 命名空间排除出录屏（这条是
  本仓库自加的，上游不写；保留是因为共享屏幕时通知入镜很尴尬）。
- 窗口规则的口径（`home/niri/windowrule.kdl` + `config.kdl` 的 `layout {}`）：
  - **上游只写两处** `window-rule`/`layer-rule`：`clavis/effects.kdl` 的 xray 和
    `clavis/layer-rules.kdl` 的 overview backdrop + 透明背景。两处都已在
    `config.kdl` 里 include；其中 backdrop 那条本仓库在 `windowrule.kdl` 里另有
    一份兜底（重复是幂等的），因为上游那份只在点 Set up 时才存在。
  - 尺寸全部来自作者演示视频的逐像素实测（1920×1080 帧 = 作者 2560×1440 @scale 1
    整屏的 0.75 倍；帧内像素 = 本机 1920×1080 @scale 1 的同比例像素）：
    **间距 75**（帧内两列之间 75、到屏幕边缘 74~76）、**大窗口 proportion 1.0**
    （窗口矩形帧内 x 75..1838 = 1762px = 屏宽的 91.8%，左右 75/82px 的留白就是 gaps：
    1.0 指工作区整宽，两侧 gaps 照扣，窗口不会贴到屏幕边缘）、
    **小窗口 ≈1155px**（帧内 1143）。
  - ⚠️ niri 的 `proportion` 是**扣掉 gaps 之后**的比例：
    `实际宽度 = p × (工作区宽 − gaps) − gaps`（niri wiki → Layout 里「proportion 0.25
    的四个窗口不管 gaps 多少都刚好铺满」只有这个公式成立）。所以小窗口写的是
    **2/3 而不是 0.6**：在 1920 宽 + gaps 75 下 2/3 得 1155px = 屏宽的 0.6（= 截图观感），
    写 0.6 只有 1032px。改 `gaps` 后小窗口实际宽度会跟着变，这正是这个比例要放在
    windowrule.kdl 里一起解释的原因。
  - 分工：全局兜底 = 小窗口 2/3（含 foot、yazi、Discord…），另外全局挂
    `open-maximized-to-edges false`，防止别的应用开窗时自己贴边满屏；
    `windowrule.kdl` 里大窗口分两组 ——
    **A 组（浏览器 / zed / blender）**：`open-maximized-to-edges true`，开窗即满屏
    （贴工作区边缘、不看 gaps、不画 border，顶栏仍在）。这是使用习惯上的选择：这三个
    常用，而且浏览器/blender 本来就会在开窗后自己请求满屏（niri 对「initial configure
    之后」的请求照办、规则拦不住），与其先开 1770 再跳一下，不如由 niri 一次给满屏。
    **B 组（obsidian / obs-studio / code / jetbrains…）**：`proportion 1.0` = 工作区
    整宽但两侧照留 gaps = 1770px（图1 的观感）。Obsidian 单独两条规则、匹配放到最宽：
    app-id 只要求**含有** `obsidian`（大小写用 `[Xx]` 类覆盖，不加 `^…$`、也不用 `(?i)`）。
    本机实测它的 `App ID` 是 **`md.Obsidian`**（标题 `… - Obsidian 1.13.7`）——
    「md. 小写 + Obsidian 大写」这种混合写法，锚定枚举全都会漏；而漏掉时的表现是
    窗口按全局兜底的 1155×878 开出来（`niri msg pick-window` 可直接读出这两个数）。
    另外还有一条**标题兜底**（同样只要求含 `obsidian`，但 `exclude` 掉终端 app-id，
    免得 nvim 打开 vault 文件时把 foot 也放大）。
    教训：niri 的 app-id 正则是**区分大小写**且在字符串里**搜**，枚举写法一定会漏，
    「点了 Mod+F 能变大、开窗却还是小的」就等于「规则没匹配上」而不是「尺寸写错」。
    浮动只有「设置」（Clavis 主控窗 0.6×0.85、nm-connection-editor /
    nwg-look 这类设置小工具 620×640）和「文件管理器」（0.6×0.85），外加它们自己的
    对话框、文件选择器、图片/视频查看器、PiP、聊天记录弹窗这类临时窗口。
    Spotify / pavucontrol 这类主窗口按口径走平铺。加新的大窗口应用 = 往对应那条正则里
    追加 app-id（`niri msg windows` 看 `App ID:` 行，注意正则区分大小写）。
  - `clavis/outputs.kdl` 里的 per-output `layout {}` 会**盖掉** `config.kdl` 的全局
    layout（这是 Clavis 设置中心「通用 → Displays」自己写的，不是本仓库的）。
    症状：间距变小、窗口变全宽。窗口宽度有 windowrule.kdl 兜着，gaps 没有 Plan B，
    所以改完窗口样式先 `cat ~/.config/niri/clavis/outputs.kdl` 确认没有 layout 块。
- **应用窗口的全局半透明 + 模糊**（`home/niri/blur.kdl`，2026-10 起默认开启）：
  - 两条规则缺一不可：`opacity 0.9` + `background-effect { blur true }`。niri 文档
    （Window Effects → Overview）明说窗口必须半透明，否则背景效果被不透明内容盖住
    —— 只想要模糊不想要透明是做不到的。
  - **xray**：默认不写 = niri 在有 blur 时自动开 `xray true`（模糊壁纸，只算一次、
    所有窗口共用；平铺窗口互不重叠，观感几乎一样，而且开窗动画/拖动时模糊不掉）。
    想要「真·玻璃」（模糊窗口下面的真实内容）就把 `blur.kdl` 里 `xray false` 的注释
    放开 —— 代价是上游标为 experimental：**开/关窗动画期间与拖动平铺窗口时模糊会
    消失**，且内容一变就要重算（Intel 核显上更明显）。
  - 例外（`windowrule.kdl`，写在后、覆盖全局）：`imv`/`mpv`/`celluloid` 与
    Picture-in-Picture 强制 `opacity 1.0` + `blur false`（半透明会毁掉画面）；
    **Blender** 同样强制 `opacity 1.0` + `blur false` —— 0.9 透明会把视口/渲染结果
    和壁纸做 alpha 混合，看到的不是真实颜色，上色和渲染时不能用；模糊本身也会在
    渲染期间持续吃核显。想再排除别的颜色敏感应用（Krita / GIMP / Inkscape /
    darktable / Resolve…）就往那条 `[Bb]lender` 正则里追加 app-id。
    Clavis 自己的主控窗/子对话框/文件选择器强制 `opacity 1.0`（它自己已经画了
    0.8 透明 + 模糊，叠上全局 0.9 会变成 0.72）。
  - ⚠️ niri 没有 `is-fullscreen` 这类匹配器，所以**浏览器里的全屏视频也会变成 0.9
    透明**。临时处理：`Mod+Shift+O`（niri 的 `toggle-window-rule-opacity`）切掉当前
    窗口的不透明规则；长期处理：把该应用的 app-id 追加进 windowrule.kdl 那条 1.0 的
    规则（`niri msg pick-window` 点一下窗口能查到 app-id）。
  - 需要 niri ≥ 26.04（`background-effect` 与 `blur{}` 都是 26.04 引入的）；本仓库
    的 niri 就是 26.04+，`niri validate` 会挡住语法回退。
- 旧 `modules/home/desktop/dynamic-wallpaper.nix`（mpvpaper 时代的壁纸轮换，依赖
  Noctalia 的 `noctalia msg`）已删除；壁纸轮换现在由 Clavis 的
  `wallpapers-rotate.py`（挂 Matugen post-hook）承担。
