# Role: home desktop — common + graphical user env
{
  imports = [
    ./common.nix
    ../../modules/home/desktop
    ../../modules/home/services
    # fcitx5 UI/hotkeys/rime profile (must be imported to take effect)
    ../../modules/home/fcitx5.nix
  ];
}
