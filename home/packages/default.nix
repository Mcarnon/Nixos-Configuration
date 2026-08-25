# User-level software, grouped by category so each can be toggled/maintained
# independently. Imported from home/default.nix.
{
  imports = [
    ./cli.nix
    ./gui.nix
    ./media.nix
    ./network.nix
    ./ai.nix
  ];
}
