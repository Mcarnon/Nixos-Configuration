# Desktop (niri + Waybar + Fuzzel) 维护手册

> 2026-08 迁移记录：原 Clavis（Quickshell 桌面壳）整套移除，按
> Sakurafall-arch/nixos-configuration 的方式把 SHORiN（shorin-arch-setup）的
> minimal-niri 桌面组件搬进 Home Manager：waybar（状态栏）+ fuzzel（启动器）
> + hyprlock（锁屏）+ awww 壁纸脚本，shell 侧同步移植 SHORiN 的 fish 函数。

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/greetd.nix` | 登录界面（ReGreet） |
| `modules/nixos/desktop/niri.nix` | niri 会话 + polkit + xdg portal 路由 |
| `modules/home/desktop/waybar/default.nix` | waybar 配置 + Nord 样式 + `waybar.service` |
| `modules/home/desktop/waybar/share_scripts.nix` | 壁纸脚本（wallpaper_random/default_wall/dynamic_wallpaper，基于 awww） |
| `modules/home/desktop/waybar/power_menu.xml` | waybar 电源菜单（关机/重启/挂起/休眠/锁定） |
| `modules/home/desktop/fuzzel.nix` | fuzzel 启动器 + `cliphist_pick` 剪贴板选择函数 |
| `modules/home/desktop/lock.nix` + `home/hyprlock.conf` | hyprlock 锁屏（Catppuccin 配色，无 Matugen 依赖） |
| `modules/home/desktop/appearance.nix` | 光标 / GTK 图标 |
| `home/niri/*.kdl` | niri 合成器（config/binds/windowrule/blur/startup） |

## 启动方式

waybar 不是由 niri `spawn-at-startup` 启动，而是作为用户 systemd 服务
（`waybar.service`，`ExecStart = waybar --log-level error`）挂在
`graphical-session.target` 下，崩溃会自动重启（沿用原 Clavis 的模式）。
fuzzel / hyprlock 是按键触发的，不需要常驻。

## 常用键位

| 键 | 功能 |
|---|---|
| `Mod+Space` | fuzzel 应用启动器 |
| `Mod+V` | 剪贴板历史（`cliphist list | fuzzel --dmenu | cliphist decode | wl-copy`） |
| `Mod+F10` / waybar 壁纸按钮 | 随机壁纸（awww） |
| `Super+Alt+L` | hyprlock 锁屏 |
| `Mod+Alt+P` | 锁屏 + 挂起 |
| waybar 电源按钮 | 关机/重启/挂起/休眠菜单 |

## 常见操作

- 改 waybar 样式/模块 → 改 `modules/home/desktop/waybar/default.nix`，重建重进会话。
- 改 niri → `nixos-rebuild switch` 后 `niri msg action quit` 重进会话。
  注意：niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件；
  想快速调参可临时 `cp` 一份真实文件，调好再同步回仓库。
- 模糊调参 → 改 `blur.kdl` 的 passes/offset，重建重进会话。
- 换壁纸 → 图片放进 `~/Pictures/wallpaper/`（脚本从那里随机选）；waybar
  中间键切默认、右键开动态轮播（每 120s 换一张）。

## 动态主题

静态配色，无运行时主题生成：

- waybar：Nord（`modules/home/desktop/waybar/default.nix` 里 `nord` palette）
- fuzzel / foot / hyprlock：Catppuccin Mocha（`fuzzel.nix`、`gui.nix`、`home/hyprlock.conf`）

## 已知取舍

- 非 xray 模糊是实验性：窗口开合动画期间不渲染。
- 登录界面用 regreet（GTK4）。
- waybar 的 `niri/window` 标题是 waybar 从 niri IPC 取的，个别 app 标题为空
  时显示 "Desktop"（rewrite 规则可再调）。
- hyprlock 的背景用当前屏幕截图（`path = screenshot`，依赖 grim），没有
  Matugen 配色联动。
