# Desktop (niri + Clavis) 维护手册

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/greetd.nix` | 登录界面（ReGreet） |
| `modules/nixos/desktop/niri.nix` | niri 会话 + polkit + xdg portal 路由 |
| `modules/home/desktop/clavis/default.nix` | 安装 `key`/`keytop` + clavis-shell/clavis-clipboard systemd 服务 |
| `pkgs/clavis-shell/` | Clavis 原生 C++ QML 模块 + QML 源码树/配置 |
| `pkgs/key-cli/` | `key` 命令（shell IPC / 生命周期 / 录屏 / 剪贴板） |
| `pkgs/keytop/` | 独立系统监视 TUI |
| `modules/home/desktop/appearance.nix` | 光标 / GTK 图标 |
| `home/niri/*.kdl` | niri 合成器（config/binds/windowrule/blur/startup） |

## 启动方式

Clavis 不是由 niri `spawn-at-startup` 启动，而是作为用户 systemd 服务
（`clavis-shell.service`，`ExecStart = key shell --foreground --no-duplicate`）
挂在 `graphical-session.target` 下，崩溃会自动重启。剪贴板监听
（`clavis-clipboard.service`）同理，跑 `key clipboard watch`。

## IPC 速查

用户命令统一经过 `key-cli`：

```bash
key shell                 # 启动 Clavis（qs -c clavis -n）
key shell --kill          # 停止
key ipc show              # 列出 IPC 目标
key ipc call TARGET METHOD [ARGS...]
```

Clavis 暴露的 IPC 目标（`AppShell.qml` / 各 Module 的 `IpcHandler`）：

| 目标 | 方法 | 用途 |
|---|---|---|
| `spotlight` | `toggle` / `open` / `close` / `web` / `openMode` | 启动器（app/壁纸/剪贴板/web 搜索） |
| `control-center` | `open(pageId)` / `close` / `toggle(pageId)` | 控制中心 / 设置中心 |
| `wallpaper` | `set` / `setForScreen` / `clear` / `previous` / `next` / `random` / `setFolder` | 壁纸 |
| `lock` | `open` / `isLocked` | 锁屏 |
| `keystone` | `dashboard` / `hub` / `tools` / `closeAllOthers` / `currentStyle` | 状态栏 Keystone |
| `weather-map` | `reloadCredentials` / `mapTilerStatus` | 天气地图 |

键位示例（`home/niri/binds.kdl`）：

- `key ipc call spotlight toggle` — 启动器
- `key ipc call control-center toggle` — 控制中心
- `key ipc call spotlight openMode wallpaper` — 壁纸选择
- `key ipc call spotlight openMode clipboard` — 剪贴板历史
- `key ipc call lock open` — 锁屏
- `key ipc call wallpaper random` — 随机壁纸

音量/亮度没有独立 IPC，直接用 `pamixer` / `brightnessctl`（已绑定 XF86 键）。

## 常见操作

- 改 Clavis 配置/主题 → 设置中心（`Mod+Comma`），或 `key shell --kill` 后重进会话。
- 改 niri → `nixos-rebuild switch` 后 `niri msg action quit` 重进会话。
  注意：niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件；
  想快速调参可临时 `cp` 一份真实文件，调好再同步回仓库。
- 模糊调参 → 改 `blur.kdl` 的 passes/offset，重建重进会话。
- 诊断 → `key doctor` / `key doctor --json`（检查 qs、gpu-screen-recorder、slurp、
  ffmpeg、pactl、cliphist、wl-copy/wl-paste 等运行时依赖）。

## 动态主题

Clavis 用 [Matugen](https://github.com/InioX/matugen) 从当前壁纸或源色生成
Material 配色方案，运行时写入 `~/.config/clavis/`。设置中心可为 btop、Cava、
Kitty、Yazi 等应用生成主题（注意：不生成 fcitx5 主题，fcitx5 用默认主题）。

## 已知取舍

- 非 xray 模糊是实验性：窗口开合动画期间不渲染。
- 登录界面用 regreet（GTK4）。
- Clavis 的壁纸/桌面卡片/状态栏是 Quickshell layer surface，其 namespace 由
  QML 定义；若壁纸偶尔盖住窗口，在 `windowrule.kdl` 加对应的
  `place-within-backdrop` layer-rule（当前已留注释占位）。
