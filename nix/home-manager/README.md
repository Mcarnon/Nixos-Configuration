# Nix Home Manager 配置

## 快速开始

```bash
# 首次安装
nix run home-manager/master -- init --switch

# 或者使用 flake（推荐）
cd ~/.config/nix/home-manager
home-manager switch --flake .#mccarnon

# 更新包
nix flake update
home-manager switch --flake .#mccarnon
```

## 目录结构

```
~/.config/nix/
├── nix.conf                    # Nix 全局配置
└── home-manager/
    ├── flake.nix               # Flake 定义
    ├── home.nix                # 主配置文件
    ├── packages.nix            # 包列表（可选，拆分用）
    ├── programs.nix            # 程序配置（可选）
    └── README.md
```

## 常用命令

```bash
# 列出已安装的包
nix-env -q

# 搜索包
nix search nixpkgs <package-name>

# 卸载包
nix-env -e <package-name>

# 清理旧版本
nix-collect-garbage
```

## 移植到新系统

1. 复制整个 `~/.config/nix/` 目录
2. 安装 Nix：`sh <(curl -L https://nixos.org/nix/install) --daemon`
3. 运行：`home-manager switch --flake .#mccarnon`
