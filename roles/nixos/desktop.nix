# Role: nixos desktop — base + graphical stack
{
  imports = [
    ./base.nix
    ../../modules/nixos/desktop
    ../../modules/nixos/hardware
  ];
}
