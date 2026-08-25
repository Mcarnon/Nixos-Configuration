# SSH: connect to another machine to sync/deploy the config remotely
# Security: hardening by default (keys only); Performance: keep minimal ciphers.
{ config, pkgs, lib, ... }:
{
  # Client-side SSH config: what `ssh` uses when connecting out.
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
  services.openssh = {
    enable = true;
    settings = {
      # Security: keys only after initial setup (initialPassword in hosts/laptop/default.nix
      # is only for first boot — change it via `passwd`, switch to agenix, then set
      # PasswordAuthentication = false and KbdInteractiveAuthentication = false).
      PasswordAuthentication = true; # TODO: flip to `false` after moving to agenix hashedPasswordFile
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      # Performance + security: modern kex/ciphers only (defaults are already sane on 26.11)
    };
  };
}
