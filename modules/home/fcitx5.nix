# Fcitx5 home-manager config (rime schema + Wayland candidate window).
# System-level fcitx5 (env vars, dbus, systemd service) lives in locales/default.nix.
{ config, pkgs, lib, ... }:
{
  # Rime default schema: rime_ice (雾凇拼音) with page size 9.
  # Without this, fcitx5-rime falls back to its built-in schema and the
  # Chinese candidate box won't appear when typing.
  xdg.configFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      menu/page_size: 9
      ascii_composer/switch_key:
        Shift_L: inline_ascii
        Shift_R: commit_text
      schema_list:
        - schema: rime_ice
  '';

  # Ensure RIME_USER_DIR is set so fcitx5-rime can deploy/compile the schema.
  home.sessionVariables = {
    RIME_USER_DIR = "$HOME/.local/share/fcitx5/rime";
  };
}
