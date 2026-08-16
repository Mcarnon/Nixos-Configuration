{ config, lib, ... }:
{
  networking.hostName = config.my.hostName;

  # NetworkManager handles both wired and wireless connections.
  networking.networkmanager.enable = true;
}
