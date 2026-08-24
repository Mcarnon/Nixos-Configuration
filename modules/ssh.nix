# SSH: connect to another machine to sync/deploy the config remotely
{ config, pkgs, lib, ... }:
{
  # Client-side SSH config: what `ssh` uses when connecting out.
  # Server/daemon settings live under `services.openssh`, see below.
  programs.ssh = {
    # Alias for the remote machine. Run `ssh nixos-remote` to connect.
    # See scripts/sync.sh for the companion sync script.
    extraConfig = ''
      Host nixos-remote
        HostName 192.168.2.68 # TODO: set to the remote IP or hostname
        User mccarnon # TODO: set to the remote username
        # Port 22
        # IdentityFile ~/.ssh/id_ed25519
    '';
  };

  # Server-side: run sshd on this machine so another machine can sync to it.
  services.openssh.enable = true;
}
