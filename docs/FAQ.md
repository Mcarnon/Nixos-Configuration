# FAQ

**改了文件 rebuild 没生效？** `git add -A` 后再 `nixos-rebuild`，flake 只读已跟踪文件。

**切显卡？** `hosts/<host>/default.nix` 改 `hardware.intel.enable -> hardware.nvidia.enable`。

**加地区？** `cp locales/zh-cn.nix locales/ja-jp.nix` 按注释改 `options.locales.ja-jp.enable`，`locales/default.nix` 加导入，`hosts` 设 `locales.ja-jp.enable = true`。

**加模块？** 复制 `modules/_templates/enable-option.nix` 到 `modules/nixos/<domain>/`，在同域 `default.nix` 注册，`roles` 或 `hosts` 设 `my.xxx.enable = true`。
