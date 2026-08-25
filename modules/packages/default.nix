# System-wide software, grouped by category so each can be toggled/maintained
# independently. A host imports `./packages` to pull in the whole set.
{
  imports = [
    ./cli.nix
    ./diagnostics.nix
  ];
}
