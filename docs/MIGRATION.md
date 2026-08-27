# 迁移指南

旧 `profiles/`、`home/profiles/`、`modules/default.nix`、`modules/{nixos,home}/default.nix`
这些垫片/聚合已删除：

- 主机入口：`hosts/laptop/default.nix` 直接 `imports = [ ../../roles/nixos/desktop.nix ]`
- home 入口：`home/default.nix` 直接 `imports = [ ../roles/home/desktop.nix ]`
- 新增域模块：放 `modules/nixos/<domain>/` 或 `modules/home/<domain>/`，并在同域目录的 `default.nix` 注册

`locales/` 仍是 locale/输入法/字体框架的 canonical 位置；`modules/nixos/i18n/` 是指向它的垫片。
