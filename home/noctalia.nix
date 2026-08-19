# Noctalia 桌面外壳 (Wayland 栏/启动器/控制中心/锁屏等)
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;

    # 用 Nix 属性集声明式生成 ~/.config/noctalia/config.toml
    # (也可以直接写 TOML 字符串或指向 .toml 文件路径)
    settings = {
      shell = {
        font = "JetBrainsMono Nerd Font";
        settings_show_advanced = true;
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };

      # 壁纸示例 (路径需真实存在)
      # wallpaper = {
      #   enabled = true;
      #   default.path = "/home/alice/Pictures/wallpaper.png";
      # };
    };

    # 若 config 校验在构建时失败, 可临时设为 false 排查
    # validateConfig = true;
  };
}
