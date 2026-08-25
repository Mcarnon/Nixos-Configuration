# Role: home desktop — common + graphical user env
{
  imports = [
    ./common.nix
    ../../modules/home/desktop
    ../../modules/home/services
  ];
}
