# 结构说明

```
flake.nix / flake-parts/{hosts,packages,checks}.nix / lib/default.nix / pkgs/  # 入口/装配/覆盖层 不动
modules/
  nixos/default.nix -> [core desktop hardware network security i18n]  # 唯一聚合
    core/{boot.nix,nix.nix,shell.nix,persist.nix,kernel.nix,cli.nix,diagnostics.nix}
    desktop/{niri.nix,greetd.nix,audio.nix}   # pipewire->audio, niri拆greetd
    hardware/{intel.nix,nvidia.nix,power.nix,disko.nix} # laptop->power
    network/{manager.nix,openssh.nix,firewall.nix}
    security/{hardening.nix,secrets.nix,sops.nix}
    i18n/ -> ../../locales  # 吸收顶级 locales/
  home/default.nix -> [shell desktop apps services]
    shell/{fish.nix,tools.nix}  # 原 home/shell.nix 拆分
    desktop/{niri.nix,noctalia.nix}
    apps/{cli,gui,media,network,ai}.nix
    services/{miyu.nix,cliphist.nix}
  _templates/  # 新模块脚手架
modules/default.nix  # 垫片 -> ./nixos
locales/  # 垫片，canonical 已迁至 modules/nixos/i18n
roles/nixos/{base.nix,desktop.nix}  # 取代 profiles/
roles/home/{common.nix,desktop.nix} # 取代 home/profiles/
profiles/ / home/profiles/  # 垫片 -> roles/
hosts/laptop/{default.nix,hardware-configuration.nix,disko-fs.nix,niri-hardware.kdl}
home/{files/miyu.fish,niri/*.kdl} / checks/miyu.nix / scripts/sync.sh  # 不动
```

**原则**：`hosts` 只放身份+硬件+选 `roles`；`modules` 按域可复用；`roles` 做组合。
