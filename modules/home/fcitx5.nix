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

      # Candidate window style
      style/font_family: "Noto Sans CJK SC"
      style/font_size: 14
      style/horizontal: true
      style/inline_preedit: false
      style/candidate_format: "%c\u2005%@\u2005"
      style/preedit_format: "%s"

      # NixOS colour scheme
      preset_color_schemes/nixos:
        name: NixOS
        text_color: 0x1a1a1a
        back_color: 0xffffff
        border_color: 0x6
        hilited_text_color: 0x000000
        hilited_back_color: 0xe8e8e8
        hilited_candidate_text_color: 0xffffff
        hilited_candidate_back_color: 0x0078d4
        candidate_text_color: 0x333333
        label_color: 0x666666
      color_scheme: nixos
  '';

  home.sessionVariables.RIME_USER_DIR = "$HOME/.config/fcitx5/rime";
}
