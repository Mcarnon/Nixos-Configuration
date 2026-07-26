# NixOS Multi-Host Configuration

支持多台主机的 NixOS 统一配置，通过 Home Manager 管理用户环境。

## 目录结构

```
nix/
├── flake.nix                          # Flake 入口（多主机 + 环境变量用户名）
├── nix.conf                           # Nix daemon 设置
├── hosts/
│   ├── common.nix                     # 所有主机共享的 NixOS 配置
│   ├── desktop/
│   │   ├── default.nix                # 桌面机特有配置
│   │   └── hardware-configuration.nix # [gitignore] 自动生成
│   └── laptop/
│       ├── default.nix                # 笔记本特有配置
│       └── hardware-configuration.nix # [gitignore] 自动生成
├── home/
│   ├── common.nix                     # Home Manager 入口
│   ├── packages.nix                   # 包列表
│   └── programs/
│       ├── git.nix                    # Git 配置
│       ├── bash.nix                   # Shell 配置
│       ├── neovim.nix                 # Neovim 配置
│       └── alacritty.nix             # Alacritty 终端配置
├── .gitignore
└── README.md
```

## 安装

### 新机器

```bash
# 1. 克隆到 /etc/nixos
sudo git clone <your-repo-url> /etc/nixos
cd /etc/nixos

# 2. 选择你的主机类型，生成硬件配置
# 桌面机：
sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix
# 笔记本：
sudo nixos-generate-config --show-hardware-config > hosts/laptop/hardware-configuration.nix

# 3. 编辑 git.nix 填写你的姓名和邮箱
#    然后一键部署（替换 USERNAME 和主机名）：
USERNAME=mccarnon sudo nixos-rebuild switch --flake .#desktop
```

### 添加新主机

1. 在 `hosts/` 下创建新目录（如 `hosts/work/`）
2. 在 `flake.nix` 的 `hosts` attrset 中添加条目
3. 生成 `hardware-configuration.nix`
4. 部署

## 更新

```bash
# 更新系统 + 用户环境（一条命令）
USERNAME=mccarnon sudo nixos-rebuild switch --flake .#desktop

# 更新 flake 输入
nix flake update
```

## Fork 使用

1. Fork 本仓库
2. 编辑 `home/programs/git.nix` 填写你的信息
3. 按上述步骤部署
