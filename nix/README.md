# NixOS + Home Manager 配置

统一管理系统配置和用户环境。

## 目录结构

```
nix-config/
├── flake.nix                      # 统一 Flake 配置
├── hosts/
│   └── default.nix                # NixOS 系统配置
│   └── hardware-configuration.nix # 硬件配置（NixOS 自动生成）
├── home-manager/
│   └── home.nix                   # 用户环境配置
├── README.md
└── .gitignore
```

## 安装（在 NixOS 上）

```bash
# 1. 克隆到 /etc/nixos
cd /etc/nixos
sudo git clone <your-repo-url> .
sudo git checkout main

# 2. 生成硬件配置（首次）
sudo nixos-generate-config --show-hardware-config > hosts/hardware-configuration.nix

# 3. 应用系统配置
sudo nixos-rebuild switch --flake .#nixos

# 4. 应用用户配置
home-manager switch --flake .#mccarnon
```

## 更新

```bash
# 更新所有
sudo nixos-rebuild switch --flake .#nixos && home-manager switch --flake .#mccarnon

# 更新 flake 输入
nix flake update
```

## 添加新用户

编辑 `flake.nix` 中的 `users`：
```nix
users = {
  mccarnon = {
    fullName = "Your Name";
    email = "your@email.com";
  };
  newuser = {
    fullName = "New User";
    email = "new@email.com";
  };
};
```

然后运行：
```bash
sudo nixos-rebuild switch --flake .#nixos
home-manager switch --flake .#newuser
```

## 从 Arch 迁移

在 Arch 上：
```bash
# 已有配置在 ~/.config/nix/
# 只需把 home-manager/ 目录内容复制到这个仓库
```

在 NixOS 上：
```bash
# 克隆仓库后，运行上面的安装命令
```
