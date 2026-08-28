# Chinese (Simplified) environment: locale settings + rime (Wusong Pinyin) + fonts
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Declarative Rime user-visible config, merged into the shared rime data so it
  # ships with the build and needs no per-user config to take effect. Rime merges
  # `default.custom.yaml` from the shared data dir on deploy.
  rimeSchemaConfig = ./rime/default.custom.yaml;

  # rime-ice presets + our custom schema, packaged as a single shared rime-data
  # source for fcitx5-rime. Output layout: `share/rime-data/` (same as rime-ice).
  rimeData = pkgs.runCommand "rime-data-fcitx5" { } ''
    mkdir -p $out/share/rime-data
    cp -r ${pkgs.rime-ice}/share/rime-data/* $out/share/rime-data/
    cp ${rimeSchemaConfig} $out/share/rime-data/default.custom.yaml
    cp ${./rime/distribution.yaml} $out/share/rime-data/distribution.yaml
  '';
in
{
  options.locales.zh-cn.enable = lib.mkEnableOption "Chinese (Simplified) locale environment";

  config = lib.mkIf config.locales.zh-cn.enable {
    locales.supportedLocales = [ "zh_CN.UTF-8/UTF-8" ];

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "zh_CN.UTF-8";
      LC_IDENTIFICATION = "zh_CN.UTF-8";
      LC_MEASUREMENT = "zh_CN.UTF-8";
      LC_MONETARY = "zh_CN.UTF-8";
      LC_NAME = "zh_CN.UTF-8";
      LC_NUMERIC = "zh_CN.UTF-8";
      LC_PAPER = "zh_CN.UTF-8";
      LC_TELEPHONE = "zh_CN.UTF-8";
      LC_TIME = "zh_CN.UTF-8";
    };

    # Rime with Wusong Pinyin; swap for fcitx5-pinyin if you prefer the classic scheme
    i18n.inputMethod.fcitx5.addons = with pkgs; [
      (fcitx5-rime.override {
        rimeDataPkgs = [ rimeData ];
      })
    ];

    fonts.fontconfig.defaultFonts = {
      sansSerif = [
        "Noto Sans CJK SC"
        "Noto Sans"
        "Noto Color Emoji"
      ];
      serif = [
        "Noto Serif CJK SC"
        "Noto Serif"
        "Noto Color Emoji"
      ];
    };
  };
}
