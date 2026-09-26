# Desktop (niri + Clavis Shell) 维护手册

> 2026-09 迁移记录：桌面壳由 Noctalia v5 切回 **Clavis Shell**（同样是
> Quickshell 外壳，IPC 统一走 `key ipc call <target> <method>`）。Clavis 没有
> 视频壁纸、没有独立窗口切换器、没有 bar 显隐开关，详见「已知取舍」。
> 登录仍是 ly，niri 合成器不变（`niri.service` 拉起，外壳挂在它下面）。

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/ly.nix` | 登录界面（ly，TUI 显示管理器） |
| `modules/nixos/desktop/niri.nix` | niri 会话 wrapper（关键：激活 graphical-session.target）+ polkit + fcitx5 服务 + xdg portal 路由 + `clavis-shell`/`key`/`keytop` 进系统 PATH |
| `home/niri/config.kdl` | niri 主配置（环境变量/光标/输入/布局/动画 + 三行 Clavis include） |
| `home/niri/binds.kdl` | 全部快捷键（`key ipc` + 音量/媒体/窗口） |
| `home/niri/blur.kdl` | 全局毛玻璃基线（blur + 窗口透明度） |
| `home/niri/windowrule.kdl` | 逐应用透明度/悬浮/中文应用规则 + layer 规则（Clavis overview 壁纸层） |
| `home/niri/startup.kdl` | 启动项（环境导入 / Clavis watchdog / xwayland-satellite / nm-applet） |
| `home/niri/clavis-static.kdl` | SHORiN 默认 niri 配色（登录后首次 niri reload 前兜底） |
| `hosts/laptop/niri-hardware.kdl` | 本机显示器输出 |
| `modules/home/desktop/clavis/default.nix` | Clavis：打包（`pkgs.clavisShell`/`keyCli`/`keytop`）+ systemd 用户服务（shell / clipboard / theme-sync）+ 定时器（壁纸轮换 / 色调库）+ 配置种子 + 壁纸脚本部署 |
| `modules/home/desktop/clavis/config.json` | 首次部署的个性化种子（壁纸/主题/效果/keystone/bar/sidebar）；**只种一次**，之后由 Clavis 自己回写 |
| `modules/home/desktop/clavis/ui-preferences.json` | 语言 / 24 小时制 / 摄氏度等 UI 种子，同样只种一次 |
| `modules/home/desktop/clavis/bin/clavis-session-env` | 启动包装：最多等 ~20s 出现 `wayland-N` socket 再 exec（黑屏修复的第二道保险） |
| `modules/home/desktop/clavis/bin/clavis-theme-sync` | 把 Clavis 的 `theme.mode` 同步给 dconf / gtk-3.0 / gtk-4.0 / Kvantum，并在 matugen 重写 kitty 主题后给 kitty 发 SIGUSR1 |
| `modules/home/desktop/clavis/nix/wallpaper-picker.py` | NyxNiri 壁纸选择器（`Mod+W`），通过 `key ipc call wallpaper set` 应用 |
| `modules/home/desktop/clavis/nix/wallpapers-rotate.py` | 半小时定时轮换，按时段色调偏好选图 |
| `modules/home/desktop/clavis/nix/scan-tones.py` | 每天 03:20 重扫壁纸色调库（`~/.config/wallpaper-tones.txt`） |
| `modules/home/desktop/appearance.nix` | 光标 breeze 24 / GTK adw-gtk3-dark / 图标 Papirus / fcitx 桥接 / fontconfig |
| `modules/home/apps/gui.nix` | foot/thunar/nautilus/imv/satty + kitty.conf（include Clavis 生成的 `themes/Matugen.conf`） |
| `checks/niri-config.nix` | flake check：跑 `niri validate` 并断言三行 Clavis include 仍是 `optional=true` |

## 启动链路

`ly (tty1)` → 选 niri 会话 → `niri-session-wrapper`（激活
`graphical-session.target`）→ `niri.service` → 按 `WantedBy=niri.service` 拉起
`clavis-shell` / `clavis-clipboard` / `clavis-theme-sync`；`startup.kdl` 再起
xwayland-satellite、nm-applet，并跑一个 watchdog：30s 后若
`key ipc show` 不通且服务非 active，就 `systemctl --user restart clavis-shell`。

三道黑屏保险：`startup.kdl` 里的 `import-environment` → `clavis-session-env`
等 socket → 服务 `Restart=always` + `StartLimitIntervalSec=0`（不会变成永久
failed）。

## 主题同步的两个触发点

`clavis-theme-sync` 由两个 `.path` 单元拉起，都指向同一个 oneshot 服务：

- `clavis-config.path` 盯 `~/.config/clavis/config.json`（深浅色来源）。
- `clavis-kitty-theme.path` 盯 `~/.config/kitty/themes/Matugen.conf`。

需要两个是因为 Clavis 换壁纸的顺序是「先写 `config.json` → 再跑 matugen」：
只看 config.json 的话，第一次同步会在 kitty 主题落地之前跑完，kitty 要等下次
换壁纸才重载。脚本本身按 `mode:Matugen.conf 亚秒 mtime` 记签名，签名不变就
直接退出，所以重复触发不会反复去戳 dconf/kitty。

## 常用键位（完整版见 `Mod+Shift+Slash` 键位教程）

| 键 | 功能 |
|---|---|
| `Mod+Space` | 应用启动器（`key ipc call spotlight toggle`） |
| `Mod+S` / `Mod+Comma` | 控制中心 toggle / open |
| `Mod+F2` | 钥石 hub（仪表盘 / 媒体 / 壁纸 / 天气） |
| `Mod+Shift+B` | 钥石 dashboard（Clavis 无 bar 显隐开关，见「已知取舍」） |
| `Mod+W` | NyxNiri 壁纸选择器 |
| `Mod+V` | 剪贴板历史（`spotlight openMode clipboard`） |
| `Mod+Return` | foot 终端 |
| `Mod+E` | nautilus 文件管理器 |
| `Mod+B` | zen-beta 浏览器 |
| `Alt+Tab` | niri 窗口总览切换（Clavis 无独立切换器） |
| `Print` / `Ctrl+Print` / `Alt+Print` | 区域 / 全屏 / 窗口截图 |
| `Mod+Shift+S` | satty 编辑最后截图 |
| `Mod+F10` | 随机壁纸（`key ipc call wallpaper random`） |
| `Mod+Shift+F10` | 下载随机动漫壁纸（`random-anime-wallpaper-clavis`） |
| `Super+Alt+L` | Clavis 锁屏 |
| `Mod+Alt+P` | 关显示器 + 锁屏 + 挂起 |

## 常见操作

- 改键位 → `home/niri/binds.kdl`（`Mod+Shift+Slash` 可查当前生效键位）。
  改完跑一次 `niri validate -c <临时目录>/config.kdl` 或 `nix flake check`
  （`checks/niri-config.nix` 会替你跑）。
- 改 niri → `nixos-rebuild switch` 后 `niri msg action quit` 重进会话。
  注意：niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件。
- 改 Clavis 外观/壁纸 → Clavis 设置中心（控制中心 → 设置）。设置写入
  `~/.config/clavis/config.json`，是运行时唯一事实来源；仓库里的
  `modules/home/desktop/clavis/config.json` **只在文件不存在时**种一次
  （`home.activation.clavisSeedConfig`），所以 GUI 改动不会被 switch 覆盖。
- Clavis 生成的文件（不要手改，会被重写）：
  - `~/.config/niri/clavis/{colors,effects,cursor}.kdl`（主配置里是 optional include）
  - `~/.config/kitty/themes/Matugen.conf`（kitty.conf include 它）
  - `~/.config/{btop,cava,yazi,...}` 的 matugen 输出、zsh/starship 配色
- 重启 Clavis → `systemctl --user restart clavis-shell`。
- 换壁纸目录 → 图放 `~/Pictures/Wallpapers/`（选择器/轮换都只扫这里）。
- 换壁纸后主题不动 → 检查 `~/.config/clavis/config.json` 的
  `theme.matugenTemplates` 是否包含需要的 id（默认 btop/cava/kitty/fcitx5/
  zsh/keytop/niri/yazi 全开），以及系统里有没有 `matugen`。
- 换壁纸后 kitty 配色不更新 → 看 `systemctl --user status clavis-kitty-theme.path`
  是不是 active（Clavis 的 `theme.matugenTemplates` 里必须有 `kitty`），再手动
  跑一次 `clavis-theme-sync` 看它有没有发 SIGUSR1。
- 桌面应用不跟着切深浅色 → `systemctl --user status clavis-theme-sync`，
  手动跑一次 `clavis-theme-sync` 看输出。

## 已知取舍

- Clavis 来自三个 `flake = false` 的源码输入（`clavis-shell` / `key-cli` /
  `keytop`），在 `pkgs/` 下用 `cmake` / `meson` / `stdenv` 打包；升级 =
  改 `flake.nix` 的 rev 后 `nix flake update`。
- **不支持视频壁纸**：Clavis 的 quickshell/awww 后端只渲染图像。库里的
  `.mp4/.webm` 保留在磁盘上，但不进选择器、不参与轮换（见
  `wallpaper_picker/config.py` 的 `LIVE_EXTENSIONS = {".gif"}`）。mpvpaper 与
  `modules/home/desktop/dynamic-wallpaper.nix` 已删除。
- Clavis 没有独立窗口切换器（`Alt+Tab` 用 niri overview，overview 壁纸由
  Clavis 画进 backdrop 层）、没有 bar 显隐开关（`Mod+Shift+B` 改成 dashboard）、
  没有音量 OSD（音量走 `pamixer`，Clavis 顶栏显示状态）。
- 壁纸取色不再重染 GTK：Clavis 没有 GTK matugen 模板，硬注入会和用户手改的
  `gtk.css` 抢文件。深浅色同步改由 `clavis-theme-sync` 负责（dconf/GTK INI/
  Kvantum），壁纸取色只影响 Clavis 自己的模板输出。
- 锁屏是 Clavis 自带；`Mod+Alt+P` 组合是「关显示器 + 锁屏 + 挂起」。
- 通知由 Clavis 接管（`layer-rule` 里把 notification 命名空间排除出录屏）。
