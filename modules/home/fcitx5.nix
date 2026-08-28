# Fcitx5 home-manager config — rime user overrides.
# System-level fcitx5 lives in locales/default.nix.
# RIME_USER_DIR is ~/.config/fcitx5/rime (XDG standard, set by NixOS).
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # default.custom.yaml: user-level patches for the system default.yaml.
  # Placed in RIME_USER_DIR so fcitx5-rime reads it on deploy.
  xdg.configFile."fcitx5/rime/default.custom.yaml".text = ''

    patch:
      menu/page_size: 9
      ascii_composer/switch_key:
        Shift_L: inline_ascii
        Shift_R: commit_text
      schema_list:
        - schema: rime_ice
  '';

  home.sessionVariables.RIME_USER_DIR = "$HOME/.config/fcitx5/rime";
}
