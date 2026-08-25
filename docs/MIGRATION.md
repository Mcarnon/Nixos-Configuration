# 迁移指南

旧 `profiles/*` / `modules/system/*` / `modules/services/*` 已保留垫片，可不改直接 `nixos-rebuild`。

渐进迁移：

1. 新主机直接 `imports = [ ../../roles/nixos/desktop.nix ]`，不再用 `profiles/`。
2. 新增域模块放 `modules/nixos/<domain>/` 并在同域 `default.nix` 注册。
3. 待全量切完后删除 `profiles/`、`home/profiles/`、`locales/` 垫片（`modules/nixos/i18n` 已接管）。
