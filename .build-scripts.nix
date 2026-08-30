# 临时验证脚本：输出 home.packages 中壁纸/音效脚本的 drvPath（验证用，用完即删）
let
  flake = builtins.getFlake (toString ./.);
  cfg = flake.nixosConfigurations.laptop.config;
  pkgs = cfg.home-manager.users.mccarnon.home.packages;
in
builtins.map (
  p:
  builtins.toString p.drvPath
) (
  builtins.filter (
    p:
    builtins.match ".*(wall|screenshot-sound|force-kill).*" (builtins.baseNameOf (builtins.toString p.drvPath))
    != null
  ) pkgs
)
