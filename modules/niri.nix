# niri (可滚动平铺 Wayland 合成器) + 登录管理器
{ config, pkgs, lib, ... }:
{
  # 启用 niri (来自 nixpkgs):
  #   - 安装 niri 包与 niri-session
  #   - 配置 xdg-desktop-portal (gnome/gtk) 与 gnome-keyring
  programs.niri.enable = true;

  # 登录管理器: greetd + tuigreet, 登录后进入 niri
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        # --cmd 指定登录成功后运行的会话命令 (niri-session 会拉起 systemd 用户会话)
        command = "${lib.getExe pkgs.tuigreet} --time --cmd ${pkgs.niri}/bin/niri-session";
      };
    };
  };

  # niri 会话 + xdg-desktop-portal 的已知修复 (参考 openbit/niri-noctalia)
  # graphical-session.target 默认 RefuseManualStart=yes, 会阻止 niri 与
  # 依赖它的服务启动, 这里放开。
  systemd.user.targets.graphical-session = {
    unitConfig = {
      RefuseManualStart = false;
      StopWhenUnneeded = false;
    };
  };
}
