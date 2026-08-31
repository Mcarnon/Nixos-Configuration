# Desktop (niri + Clavis) 维护手册

> 2026-08 翻新记录：桌面壳换回 Clavis（xy1092/clavis-shell 镜像，
> 上游 StatIndet/quickshell）。桌面组件改为 keystone 状态栏 + Spotlight
> 启动器 + 控制中心 + Clavis 锁屏 + Matugen M3 动态主题，替换掉 Shorin
> 时代的 waybar/fuzzel/hyprlock/mako。登录仍是 ly，niri 合成器不变。

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/ly.nix` | 登录界面（ly，TUI 显示管理器） |
| `modules/nixos/desktop/niri.nix` | niri 会话 wrapper（关键：激活 graphical-session.target）+ polkit + fcitx5 服务 + xdg portal 路由 |
| `home/niri/config.kdl` | niri 主配置（环境变量/光标/输入/布局/动画） |
| `home/niri/binds.kdl` | 全部快捷键（Clavis IPC + 音量/媒体/窗口） |
| `home/niri/blur.kdl` | 全局毛玻璃基线（blur + 窗口透明度） |
| `home/niri/windowrule.kdl` | 逐应用透明度/悬浮/中文应用规则 + layer 规则 |
| `home/niri/startup.kdl` | 启动项（xwayland-satellite / nm-applet / key shell 兜底） |
| `hosts/laptop/niri-hardware.kdl` | 本机显示器输出 |
| `modules/home/desktop/clavis/default.nix` | Clavis：keyCli/keytop/awww + 两个 systemd 用户服务（shell、clipboard）+ 默认壁纸部署 |
| `pkgs/clavis-shell/` `pkgs/key-cli/` `pkgs/keytop/` `pkgs/libcava/` | Clavis 全家桶打包（overlay 聚合在 `pkgs/default.nix`） |
| `modules/home/desktop/appearance.nix` | 光标 volantes / GTK adw-gtk3-dark / 图标 Papirus / fcitx 桥接 / fontconfig |
| `modules/home/apps/gui.nix` | foot/thunar/nautilus/imv/satty + Thunar 配置 |

## 启动链路

`ly (tty1)` → 选 niri 会话 → `niri-session-wrapper`（激活
`graphical-session.target`）→ niri.service → 拉起 clavis-shell /
clavis-clipboard / polkit / fcitx5 用户服务；`startup.kdl` 再起
xwayland-satellite、nm-applet，并 `key shell --no-duplicate` 兜底
（systemd 服务已起时不会双开）。

## 常用键位（完整版见 `Mod+Shift+Slash` 键位教程）

| 键 | 功能 |
|---|---|
| `Mod+Space` | Spotlight 启动器 |
| `Mod+S` / `Mod+Comma` | 控制中心（toggle / open） |
| `Mod+W` | 壁纸选择（Spotlight wallpaper 模式） |
| `Mod+V` | 剪贴板历史（Spotlight clipboard 模式） |
| `Mod+Shift+B` | keystone 仪表盘 |
| `Mod+Return` | foot 终端 |
| `Mod+E` | nautilus 文件管理器 |
| `Mod+B` | zen-beta 浏览器 |
| `Alt+Tab` | niri 窗口总览切换 |
| `Print` / `Ctrl+Print` / `Alt+Print` | 区域 / 全屏 / 窗口截图 |
| `Mod+Shift+S` | satty 编辑最后截图 |
| `Mod+F10` | 随机壁纸（`key ipc call wallpaper random`） |
| `Super+Alt+L` | Clavis 锁屏 |
| `Mod+Alt+P` | 锁屏 + 挂起 |

## 常见操作

- 改键位 → `home/niri/binds.kdl`（`Mod+Shift+Slash` 可查当前生效键位）。
- 改 niri → `nixos-rebuild switch` 后 `niri msg action quit` 重进会话。
  注意：niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件。
- 改 Clavis 外观/壁纸 → Clavis 设置中心（控制中心 → 设置），运行时写入
  `~/.config/clavis/`；主题色由 Matugen 按壁纸生成。
- Clavis 重启 → `systemctl --user restart clavis-shell`（或 `key shell --kill` 后
  自动拉起）。
- 换壁纸目录 → 图放 `~/Pictures/Wallpapers/`（Clavis 设置中心从这里选）。

## 已知取舍

- Clavis 全家桶（clavis-shell/key-cli/keytop）用的是 xy1092 镜像（上游
  StatIndet/quickshell 的快照），升级 = 更新 flake.lock 里的三个输入。
- `key-cli` 的 wrapper 把 quickshell/matugen/cliphist/wl-clipboard/
  gpu-screen-recorder/ffmpeg/slurp/pipewire 加进 PATH，Clavis 调外部工具
  不需要额外安装；awww 单独在 clavis 模块里装。
- 锁屏是 Clavis 自带（layer surface），不再是 hyprlock；休眠组合
  `Mod+Alt+P` 会先 `key ipc call lock open` 再挂起。
- 通知由 Clavis 接管（`layer-rule` 里把 notification 命名空间排除出录屏）。
