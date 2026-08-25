# Screenshot / clipboard / volume tools.
# 注意：cliphist 服务已迁移至 modules/home/services/cliphist.nix (services.cliphist.enable)
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    grim # screenshot
    slurp # region select for screenshots
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste)
    pamixer # volume control (fallback; Noctalia has its own OSD)
    cliphist # clipboard history store
  ];
}
