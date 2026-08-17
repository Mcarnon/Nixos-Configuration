# VM.
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos-vm";

  # 引导、SSH 等之后逐步添加。
}
