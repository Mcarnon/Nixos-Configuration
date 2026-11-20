# FAQ

**改了文件 rebuild 没生效？** `git add -A` 后再 `nixos-rebuild`，flake 只读已跟踪文件。

**切显卡？** `hosts/<host>/default.nix` 改 `hardware.intel.enable -> hardware.nvidia.enable`。

**加地区？** `cp locales/zh-cn.nix locales/ja-jp.nix` 按注释改 `options.locales.ja-jp.enable`，`locales/default.nix` 加导入，`hosts` 设 `locales.ja-jp.enable = true`。

**加模块？** 复制 `modules/_templates/enable-option.nix` 到 `modules/nixos/<domain>/`，在同域 `default.nix` 注册，`roles` 或 `hosts` 设 `my.xxx.enable = true`。

**Horizon 点 Play 报 `Could not complete game launch: bind holder control socket: permission denied`？** 已修：`pkgs/horizon-launcher` 给 buildFHSEnv 的沙箱追加 `--tmpfs /tmp`。原因是 bwrap 的 user namespace 只映射当前 uid，宿主 root 在沙箱里 stat 成 65534，而 horizon 的 holder 控制 socket 会检查父目录「属于自己或 root」，`/run/user` 的上级和 `/tmp` 全部中招。上游修好后删掉该目录、`gui.nix` 改回 `inputs.horizon.packages.<system>.default` 即可。
