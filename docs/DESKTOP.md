# Desktop (niri + Noctalia v5) 维护手册

> 2026-09 迁移记录：桌面壳由 Clavis 切换为 **Noctalia**，随后升级到
> **v5**（原生 C++/TOML，IPC 从 `qs -c noctalia-shell ipc call` 改为
> `noctalia msg`）。SHORiN 外观用 v5 TOML 复刻（config/config.toml +
> templates.toml）。登录仍是 ly，niri 合成器不变。

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/ly.nix` | 登录界面（ly，TUI 显示管理器） |
| `modules/nixos/desktop/niri.nix` | niri 会话 wrapper（关键：激活 graphical-session.target）+ polkit + fcitx5 服务 + xdg portal 路由 |
| `home/niri/config.kdl` | niri 主配置（环境变量/光标/输入/布局/动画） |
| `home/niri/binds.kdl` | 全部快捷键（Noctalia IPC + 音量/媒体/窗口） |
| `home/niri/blur.kdl` | 全局毛玻璃基线（blur + 窗口透明度） |
| `home/niri/windowrule.kdl` | 逐应用透明度/悬浮/中文应用规则 + layer 规则 |
| `home/niri/startup.kdl` | 启动项（xwayland-satellite / nm-applet / 环境导入） |
| `home/niri/noctalia-static.kdl` | SHORiN 默认 niri 配色（登录后首次 niri reload 前兜底） |
| `hosts/laptop/niri-hardware.kdl` | 本机显示器输出 |
| `modules/home/desktop/noctalia/default.nix` | Noctalia v5：官方 home 模块 + systemd 用户服务 + TOML 配置 + 默认壁纸 + 随机壁纸脚本 |
| `modules/home/desktop/noctalia/config/config.toml` | v5 主配置（复刻 SHORiN 外观：bar/组件/主题/壁纸/dock/osd） |
| `modules/home/desktop/noctalia/config/templates.toml` | v5 用户模板（fcitx5 / gtk-folder） |
| `modules/home/desktop/appearance.nix` | 光标 volantes / GTK adw-gtk3-dark / 图标 Papirus / fcitx 桥接 / fontconfig |
| `modules/home/apps/gui.nix` | foot/thunar/nautilus/imv/satty + Thunar 配置 |

## 启动链路

`ly (tty1)` → 选 niri 会话 → `niri-session-wrapper`（激活
`graphical-session.target`）→ niri.service → 拉起 noctalia /
polkit / fcitx5 用户服务；`startup.kdl` 再起 xwayland-satellite、
nm-applet。

## 常用键位（完整版见 `Mod+Shift+Slash` 键位教程）

| 键 | 功能 |
|---|---|
| `Mod+Space` | 应用启动器 |
| `Mod+S` / `Mod+Comma` | 控制中心 toggle |
| `Mod+W` | 壁纸选择器 |
| `Mod+V` | 剪贴板历史 |
| `Mod+Shift+B` | 状态栏显隐 |
| `Mod+Return` | foot 终端 |
| `Mod+E` | nautilus 文件管理器 |
| `Mod+B` | zen-beta 浏览器 |
| `Alt+Tab` | niri 窗口总览切换 |
| `Print` / `Ctrl+Print` / `Alt+Print` | 区域 / 全屏 / 窗口截图 |
| `Mod+Shift+S` | satty 编辑最后截图 |
| `Mod+F10` | 随机壁纸（`noctalia msg wallpaper-random`） |
| `Super+Alt+L` | Noctalia 锁屏 |
| `Mod+Alt+P` | 锁屏 + 挂起 |

## 常见操作

- 改键位 → `home/niri/binds.kdl`（`Mod+Shift+Slash` 可查当前生效键位）。
- 改 niri → `nixos-rebuild switch` 后 `niri msg action quit` 重进会话。
  注意：niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件。
- 改 Noctalia 外观/壁纸 → Noctalia 设置中心（控制中心 → 设置），GUI 覆盖写入
  `~/.local/state/noctalia/settings.toml`；声明式配置在
  `modules/home/desktop/noctalia/config/config.toml`（用户层，GUI 覆盖优先）。
  主题色由 Noctalia 按壁纸原生生成（`[theme].source = "wallpaper"`）。
- Noctalia 重启 → `systemctl --user restart noctalia`。
- 换壁纸目录 → 图放 `~/Pictures/Wallpapers/`（Noctalia 壁纸选择器从这里选）。
- 随机动漫壁纸 → `random-anime-wallpaper-noctalia`（下载到
  `~/Pictures/Wallpapers/api-random-download`）。

## 已知取舍

- Noctalia v5 来自 flake 输入 `github:noctalia-dev/noctalia`（配 Cachix
  二进制缓存），升级 = `nix flake update noctalia`（或更新 flake.lock）。
- Noctalia v5 模板会按壁纸生成 GTK（`~/.config/gtk-*/noctalia.css`）、niri
  配色（`~/.config/niri/noctalia.kdl`）等；这些文件由 Noctalia 运行时管理，
  Nix 只提供初始配置和模板源文件（templates/、templates.toml）。
- 锁屏是 Noctalia 自带；休眠组合 `Mod+Alt+P` 会锁屏后挂起。
- 通知由 Noctalia 接管（`layer-rule` 里把 notification 命名空间排除出录屏）。
