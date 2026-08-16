# Home-manager configuration for the primary user.
#
# Put user-level programs here (shell, editor, git, terminal tools, etc.).
# System-level services belong in `modules/` or `hosts/<name>/default.nix`.
{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    # git
    # vim
    # ...
  ];

  # Example: a modern default shell (uncomment to enable).
  # programs.bash.enable = true;
  # programs.starship.enable = true;
}
