# Laptop.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  # 引导、硬件、桌面等之后逐步添加。
}
