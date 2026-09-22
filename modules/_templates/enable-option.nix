# 模板：带开关的 NixOS 模块
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.example;
in
{
  options.my.example.enable = lib.mkEnableOption "example feature";

  config = lib.mkIf cfg.enable {
    # 你的配置
    # environment.systemPackages = with pkgs; [ hello ];
  };
}
