# Desktop.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "desktop";

  # 引导、硬件、桌面等之后逐步添加。
}
