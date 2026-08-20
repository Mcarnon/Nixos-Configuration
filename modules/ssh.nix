# SSH: connect to another machine to sync/deploy the config remotely
{ config, pkgs, lib, ... }:
{
  programs.ssh = {
    enable = true;
    startAgent = true;

    matchBlocks = {
      # Alias for the remote machine. Run `ssh nixos-remote` to connect.
      # See scripts/sync.sh for the companion sync script.
      "nixos-remote" = {
        hostname = "192.168.1.100"; # TODO: set to the remote IP or hostname
        user = "alice";             # TODO: set to the remote username
        # port = 22;
        # identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  # Optional: also run sshd on this machine so another machine can sync to it.
  # services.openssh = {
  #   enable = true;
  #   settings.PasswordAuthentication = false;
  # };
}
