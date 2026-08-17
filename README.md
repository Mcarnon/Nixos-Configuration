# NixOS Configuration

个人 NixOS 配置骨架，基于 **Flakes**，支持 **desktop** / **laptop** / **vm** 三台机器。

## 目录结构

```
.
├── flake.nix            # 入口：输入源 + 三个 host
├── hosts/
│   ├── desktop/
│   ├── laptop/
│   └── vm/
│       ├── default.nix
│       └── hardware-configuration.nix   # 占位，用 nixos-generate-config 生成
└── modules/
    └── default.nix      # 共享基础配置（目前为空）
```

## 使用

```bash
git clone <repo-url> ~/nixos-config
cd ~/nixos-config

# 首次：生成这台机器的硬件配置，覆盖占位文件
sudo nixos-generate-config --show-hardware-config > hosts/laptop/hardware-configuration.nix

# 重建
sudo nixos-rebuild switch --flake .#laptop
```

不在仓库目录时：

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#laptop
```

## 说明

- 目前只有框架骨架，具体配置（用户、桌面、硬件细节等）之后逐步添加。
- `nixpkgs` 走清华 TUNA 镜像（滚动版）；想用稳定版把 `flake.nix` 里的 `nixpkgs-unstable` 换成 `nixos-26.05`。
- `flake.lock` 要提交以保持可复现；不要提交任何密钥。
- 格式化代码用 `nix fmt`。
