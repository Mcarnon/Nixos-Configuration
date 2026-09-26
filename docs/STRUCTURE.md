# 结构说明

```
flake.nix / flake-parts/{hosts,packages,checks}.nix / lib/default.nix / pkgs/  # 入口/装配/覆盖层
modules/
  nixos/
    core/{boot.nix,nix.nix,shell.nix,persist.nix,kernel.nix,cli.nix,diagnostics.nix}
    desktop/{niri.nix,ly.nix,audio.nix}          # 登录 ly, pipewire->audio
    hardware/{intel.nix,nvidia.nix,power.nix,disko.nix}
    network/{manager.nix,openssh.nix,firewall.nix}
    security/{hardening.nix,secrets.nix,sops.nix}
    i18n/ -> ../../locales                        # 垫片，canonical 在 locales/
  home/
    shell/{fish.nix,tools.nix}
    desktop/{niri.nix,appearance.nix,clavis/} # Clavis（Quickshell 桌面壳）
    apps/{cli,gui,media,network,ai,neovim}.nix
    services/{miyu.nix}
  _templates/                                     # 新模块脚手架
locales/{default.nix,zh-cn.nix}                   # locale/输入法/字体框架（canonical）
roles/nixos/{base.nix,desktop.nix}                # 主机组合
roles/home/{common.nix,desktop.nix}               # 用户组合
hosts/laptop/{default.nix,hardware-configuration.nix,disko-fs.nix,niri-hardware.kdl}
home/{default.nix,files/{miyu.fish,f.fish,fwatch.fish,foot.ini,...},niri/{config,binds,blur,startup,windowrule}.kdl} / wallpapers/ / docs/ / checks/ / scripts/ / .github/
```

**原则**：`hosts` 只放身份+硬件+选 `roles`；`modules` 按域可复用；`roles` 做组合。
