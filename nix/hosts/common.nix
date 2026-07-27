{ config, pkgs, lib, username, inputs, ... }:

{
  # === 引导 ===
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;

  # === 网络 ===
  networking.networkmanager.enable = true;

  # === 时区和语言 ===
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # === 用户 ===
  users.users.mccarnon = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.bash;
  };

  # === 系统包 ===
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    xwayland-satellite
  ];

  # === Wayland 环境变量 ===
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    WINIT_UNIX_BACKEND = "wayland";
    GTK_USE_PORTAL = "1";
  };

  # === Niri (Wayland compositor) ===
  programs.niri.enable = true;

  # === Greetd (登录管理器) ===
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${config.programs.niri.package}/bin/niri-session";
        user = username;
      };
    };
  };

  # NixOS 默认会给 niri.service 注入精简 PATH，禁用以继承完整 PATH
  systemd.user.services.niri.enableDefaultPath = false;

  # === Polkit (权限提升) ===
  security.polkit.enable = true;

  # === Noctalia Shell (桌面 shell) ===
  imports = [ inputs.noctalia.nixosModules.default ];
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # === PAM (锁屏支持) ===
  security.pam.services = {
    swaylock = {};
    niri = {};
  };

  # === 音频 (PipeWire) ===
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # === Snapper (Btrfs 快照) ===
  services.snapper = {
    configs.root = {
      SUBVOLUME = "/";
      TIMELINE_CREATE = false;
      TIMELINE_CLEANUP = true;
      TIMELINE_MIN_AGE = "1800";
    };
  };

  # === XDG Portal (文件选择器等) ===
  xdg.portal = {
    enable = true;
    config.niri = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  # === Nix 设置 ===
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # === 系统版本 ===
  system.stateVersion = "26.05";
}
