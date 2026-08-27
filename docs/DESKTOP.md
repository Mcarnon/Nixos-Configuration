# Desktop (niri + Noctalia) 维护手册

## 各文件职责

| 路径 | 管什么 |
|---|---|
| `modules/nixos/desktop/greetd.nix` | 登录界面（ReGreet） |
| `modules/nixos/desktop/niri.nix` | niri 会话 + polkit + xdg portal 路由 |
| `modules/home/desktop/noctalia/default.nix` | enable + 字体/面板/启动器/通知/OSD |
| `modules/home/desktop/noctalia/theme.nix` | 配色 / 模板 / 夜间模式 / 定位 |
| `modules/home/desktop/noctalia/bar.nix` | 状态栏 widget + 控制中心 + dock |
| `modules/home/desktop/noctalia/wallpaper.nix` | 壁纸 / 轮换 / 动态壁纸插件 |
| `modules/home/desktop/noctalia/lockscreen.nix` | 锁屏 / 电源菜单 / 空闲 |
| `modules/home/desktop/noctalia/integrations.nix` | hooks / launcher providers / 自定义模板 |
| `modules/home/desktop/appearance.nix` | 光标 / GTK 图标 |
| `home/niri/*.kdl` | niri 合成器（config/binds/windowrule/blur/startup） |

## 壁纸目录约定

- `~/Pictures/Wallpapers/` 静态图（轮换 + 过渡）
- `~/Pictures/Wallpapers/video/` 动态壁纸 `.mp4`（mpvpaper 插件）
- `wallpapers/`（仓库内）登录界面固定背景（进 store，可复现）

## 常见操作

- 改 Noctalia → `nixos-rebuild switch`（构建期 `noctalia config validate` 兜底）
- 改 niri → `nixos-rebuild switch` 后 `niri msg action quit` 重进会话。
  注意：niri 配置是 store 软链，不能直接改 `~/.config/niri` 下的文件；
  想快速调参可临时 `cp` 一份真实文件，调好再同步回仓库。
- 动态壁纸插件更新 → `noctalia msg plugins update official`
- 插件状态 → `noctalia msg plugins list`；IPC 全表 → `noctalia msg --help`
- 模糊调参 → 改 `blur.kdl` 的 passes/offset，重建重进会话

## 已知取舍

- 主题模板不含 `"niri"`：niri 配置是 store 软链，Noctalia 模板脚本无法改写。
  想让焦点环跟壁纸颜色，可把 niri 配置改为真实文件，或用自定义模板输出独立
  `colors.kdl` 再 `include`。
- 非 xray 模糊是实验性：窗口开合动画期间不渲染。
- 登录界面用 regreet（GTK4）；想更接近 Noctalia 外观可后续评估 Noctalia
  Greeter（nixpkgs 未收录，需自行打包或加 flake input）。

## 进阶：全声明式动态壁纸插件

默认用内置 official git 源（首次启动自动拉取）。想插件代码也进 store、完全
可复现，先在 `flake.nix` 加 `official-plugins` input（`flake = false`，该仓库
不是 flake），再把 `wallpaper.nix` 改为 `path` 源：

```nix
programs.noctalia.settings.plugins = {
  enabled = [ "noctalia/mpvpaper" ];
  auto_update = "none";
  source = [
    {
      name = "nix-official";
      kind = "path";
      location = "${inputs.official-plugins}";
      enabled = true;
    }
  ];
};
```

## IPC 速查

- Noctalia：Unix socket `$XDG_RUNTIME_DIR/noctalia-$WAYLAND_DISPLAY.sock`
  （非 TCP 端口，无冲突；`noctalia msg <command>` 调用）
- niri：`niri msg <command>` / `niri msg --json`（脚本用）
- 键位示例：`noctalia msg panel-toggle launcher`、`noctalia msg session lock`
