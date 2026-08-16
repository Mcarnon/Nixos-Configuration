{ config, lib, pkgs, ... }:
{
  users.users.${config.my.username} = {
    isNormalUser = true;
    description = config.my.fullName;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
    ];

    # TODO: replace with a real password or remove once you can log in via SSH.
    # On first boot log in with "changeme" and run `passwd` to set a real one.
    initialPassword = "1234";
  };
}
