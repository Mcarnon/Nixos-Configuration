# Secrets via agenix: age-encrypted files that decrypt only on the target host.
#
# The private key never leaves the machine; the repo only holds the encrypted
# `<name>.age` blobs. At activation, agenix decrypts them into
# `/run/agenix.d/<name>` (tmpfs) so the plaintext never lands in the Nix store
# or on disk.
#
# To add your first secret:
#   1. On the laptop, make sure the age identity exists (an SSH ed25519 key):
#        ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519   # if you don't have one
#   2. Declare it below, e.g.:
#        age.secrets.user-password.file = ../secrets/user-password.age;
#   3. Create the encrypted file (edit → paste secret → save):
#        nix run github:ryantm/agenix -- -e secrets/user-password.age
#   4. Consume it, e.g. for the login password (paste `mkpasswd -m sha-512` output
#      into the secret, then):
#        users.users.<name>.hashedPasswordFile = config.age.secrets.user-password.path;
#   5. Rebuild: sudo nixos-rebuild switch --flake .#laptop
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Where agenix looks for the private key at activation.
  # Uses the same SSH key as modules/ssh.nix; TODO: keep in sync with your user.
  age.identityPaths = [ "/home/mccarnon/.ssh/id_ed25519" ];

  # Example (uncomment + create the .age file as above):
  # age.secrets.user-password = {
  #   file = ../secrets/user-password.age;
  #   owner = "mccarnon";
  #   group = "users";
  # };
}
