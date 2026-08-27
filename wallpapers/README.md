# 登录界面背景

把登录界面背景放到这里（相对路径会被复制进 Nix store，greeter 用户可读且可复现）：

- `login.png` —— 静态背景（推荐）
- `login.mp4` —— 视频/动态背景（ReGreet 内置 GStreamer 支持）

放好文件后在 `modules/nixos/desktop/greetd.nix` 里取消注释 `settings.background`
块，并把 `path` 指向对应文件。
