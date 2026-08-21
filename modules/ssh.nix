# SSH client aliases (system-wide /etc/ssh/ssh_config).
#
# Note: `services.openssh.*` configures the SSH *server* (sshd). Client-side
# `Host` blocks belong under `programs.ssh.extraConfig` instead.
{ ... }:
{
  programs.ssh.extraConfig = ''
    Host nixos-remote
      HostName 192.168.2.68
      User mccarnon
  '';
}
