# Desktop (niri + SHORiN minimal-niri) 维护手册

> 2026-08 翻新记录：桌面环境整体换成 SHORiN（shorin-arch-setup）的
> minimal-niri 方案——登录 ly、锁屏 hyprlock、状态栏 waybar、启动器 fuzzel、
> 通知 mako、终端 foot、文件管理器 Thunar、截图 satty、图片 imv、视频 mpv。
> 之前两代（Noctalia → Clavis，Quickshell 桌面壳）彻底移除。
> 与 Shorin 原版的差异：去 AUR 专属项（quicksave/quickload/shorinclip/
> linuxqq-clipsync），浏览器换成 zen-beta，壁纸脚本（awww）为仓库自备扩展。

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/ly.nix` | 登录界面（ly，TUI 显示管理器，Shorin 同款） |
| `modules/nixos/desktop/niri.nix` | niri 会话 wrapper + polkit + fcitx5 服务 + xdg portal 路由 |
| `home/niri/config.kdl` | niri 主配置（环境变量/光标/输入/recent-windows/启动项） |
| `home/niri/binds.kdl` | 全部快捷键（SHORiN 键位方案） |
| `home/niri/rule.kdl` | 窗口/layer 规则（悬浮、隐私、steam 修复） |
| `home/niri/layout.kdl` | 布局（间距/阴影/宽度预设） |
| `hosts/laptop/niri-hardware.kdl` | 本机显示器输出（对应 Shorin 的 output.kdl） |
| `home/niri/hyprlock.conf` + `hyprlock-colors.conf` | 锁屏（原版配色变量已硬编码，无 Matugen 依赖） |
| `home/niri/scripts/` | 纯脚本（niri-binds 键位教程 / quick-switch / niri-pick / wlsunset） |
| `modules/home/desktop/niri.nix` | 上述文件接线 + `screenshot-sound` / `niri-force-kill-window` 包装包 |
| `modules/home/desktop/waybar/` | waybar 原版 config.jsonc + style.css + awww 壁纸脚本 |
| `modules/home/desktop/fuzzel.nix` | fuzzel 启动器（原版 fuzzel.ini） |
| `modules/home/desktop/lock.nix` | hyprlock 安装 + 配置接线 |
| `modules/home/desktop/mako.nix` | 通知守护（原版 mako 配置） |
| `modules/home/desktop/appearance.nix` | 光标 breeze / GTK adw-gtk3-dark / 图标 Papirus / fcitx 桥接 / fontconfig |
| `modules/home/apps/gui.nix` | foot/thunar/nautilus/imv/satty/wlogout + Thunar 配置 |
| `home/files/` | foot/fuzzel/mako/mpv/satty/fastfetch/fonts/mimeapps/thunar/wlogout 配置 |

## 启动链路

`ly (tty1)` → 选 niri 会话 → `niri-session-wrapper`（激活
`graphical-session.target`）→ niri.service → 拉起 waybar/mako/polkit/fcitx5
用户服务；`config.kdl` 的 `spawn-at-startup` 再起 foot server、cliphist
监听、wlsunset 护眼、screenshot-sound 音效、swayosd-server、xhost。

## 常用键位（完整版见 `Mod+Shift+Slash` 键位教程）

| 键 | 功能 |
|---|---|
| `Mod+Z` / `Mod+Space` | fuzzel 应用启动器 |
| `Mod+T` / `Mod+Return` | footclient / foot 终端 |
| `Mod+E` | Thunar（回退 nautilus） |
| `Mod+B` | zen-beta 浏览器 |
| `Alt+Tab` | fuzzel 窗口快速切换 |
| `Mod+Alt+V` | 剪贴板历史（cliphist+fuzzel） |
| `Mod+Alt+A` / `Print` | 区域截图（带快门音效） |
| `Mod+Shift+S` | satty 编辑最后截图 |
| `Mod+F10` | 随机壁纸（图片放 `~/Pictures/Wallpapers/`） |
| `Mod+F9` | 护眼模式（wlsunset） |
| `Mod+Alt+L` | hyprlock 锁屏 |
| `Mod+Alt+P` | 锁屏 + 挂起 |
| `Mod+Shift+Ctrl+Q` | wlogout 电源菜单 |

## 常见操作

- 改 waybar → `modules/home/desktop/waybar/{config.jsonc,style.css}`，重建重进会话。
- 改键位 → `home/niri/binds.kdl`（`Mod+Shift+Slash` 可查当前生效键位）。
- 改锁屏 → `home/niri/hyprlock.conf` + `hyprlock-colors.conf`。
- 改 niri → `nixos-rebuild switch` 后 `niri msg action quit` 重进会话。
  注意：niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件。
- 截图没声音 → `systemctl --user status screenshot-sound` 或确认 pipewire 在跑。
- 音量没 OSD → `systemctl --user status swayosd-server`（binds 会回退 wpctl）。

## 已知取舍

- 壁纸脚本（awww）是本仓库扩展：Shorin 的 minimal-niri 本体没有壁纸守护，
  `~/Pictures/Wallpapers` 里放图即可 `Mod+F10` 随机切换。
- waybar 是 Shorin 原版默认示例样式（彩色块），不是 Nord；想要 Nord 可把
  旧版（git 历史里的 waybar/default.nix）捡回来改。
- foot 字体是 Maple Mono NF（`pkgs.maple-mono`），若该字体家族名对不上会
  回退到字体列表里的下一个（fontconfig 已把 JetBrainsMono Nerd Font 放第二位）。
- hyprlock 背景用当前屏幕截图（`path = screenshot`，依赖 grim）。
