# Module summary: all reusable system modules are imported here.
# A host only needs to import `../../modules` to pull in the whole set.
{
  imports = [
    ./boot.nix
    ./network.nix
    ./nix.nix
    ./cli.nix
    ./diagnostics.nix
    ./shell.nix
    ./snapshot.nix
    ./niri.nix
    ./audio.nix
    ./laptop.nix
    ./ssh.nix
  ];
}
