# niri compositor (login manager lives in ./ly.nix)
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Wayland session entry point (replaces the default niri-session).
  #
  # niri-session only activates graphical-session.target when it launches
  # niri.service itself. But under ly (a display manager) the session already
  # runs inside a systemd --user manager, so niri-session takes its "already
  # managed" shortcut and execs `niri --session` directly — leaving
  # graphical-session.target inactive, which means every user service
  # `WantedBy=graphical-session.target`（noctalia, fcitx5, polkit）永远
  # 不会启动。显式启动 niri.service 可修复此问题：它
  # BindsTo=graphical-session.target，目标被激活后会把
  # 所有用户服务一并拉起。`systemctl --wait` 让本进程存活到
  # 注销，显示管理器才能正确跟踪会话。
  niriSessionWrapperScript = pkgs.writeShellScriptBin "niri-session-wrapper" ''
    # 确保 user systemd 会话可用（ly 经 pam_systemd 通常会设置，这里兜底）
    # 注意：bash 变量只用 $VAR 形式；带花括号的展开会与 Nix 字符串插值冲突。
    if [ -z "$XDG_RUNTIME_DIR" ]; then
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi
    mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || true
    chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

    systemctl --user reset-failed 2>/dev/null || true
    systemctl --user import-environment 2>/dev/null || true
    dbus-update-activation-environment --all 2>/dev/null || true

    # 启动失败时把原因打出来，方便 journalctl 定位
    if ! systemctl --user start --wait niri.service; then
      echo "niri.service failed to start:" >&2
      systemctl --user status niri.service --no-pager 2>&1 | tail -30 >&2
      exit 1
    fi
  '';

  # niri package whose shipped wayland-session .desktop is overridden so
  # ly launches the wrapper (which activates graphical-session.target)
  # instead of the bare `niri-session` (which doesn't). Everything else from the
  # niri package (binaries, niri.service, portals) is preserved via symlinkJoin.
  niriWithSessionWrapper =
    (pkgs.symlinkJoin {
      name = "niri-with-session-wrapper";
      # 关键：wrapper 脚本本身必须作为 path 装进最终包，否则 .desktop
      # 引用的 bin/niri-session-wrapper 不存在，会话启动即失败（登录循环）。
      paths = [ pkgs.niri niriSessionWrapperScript ];
      postBuild = ''
        rm -f "$out/share/wayland-sessions/niri.desktop"
        cat > "$out/share/wayland-sessions/niri.desktop" <<EOF
        [Desktop Entry]
        Name=Niri
        Comment=niri + graphical-session.target user services (fcitx5, polkit, ...)
        Exec=${niriSessionWrapperScript}/bin/niri-session-wrapper
        Type=Application
        DesktopNames=niri
        EOF
      '';
    })
    // {
      # The display-manager's `sessionPackages` type requires this metadata;
      # symlinkJoin drops it, so re-attach it from the underlying niri package.
      providedSessions = pkgs.niri.providedSessions or [ "niri" ];
    };
  # 等 niri 把 WAYLAND_DISPLAY 写进 systemd user 环境后再启动 fcitx5。
  # fcitx5 的 Wayland 前端依赖 WAYLAND_DISPLAY；若它比 niri 的
  # spawn-sh-at-startup 更早启动，会退回无前端状态（托盘无图标、候选框不弹，
  # 症状等同"输入法没加载"）。与 noctalia-launch 相同的轮询逻辑。
  fcitx5Launch = pkgs.writeShellScriptBin "fcitx5-launch" ''
    PATH="${lib.makeBinPath [ pkgs.systemd pkgs.coreutils pkgs.gnugrep ]}"
    for i in $(seq 1 60); do
      if systemctl --user show-environment 2>/dev/null | grep -q '^WAYLAND_DISPLAY='; then
        eval "$(${pkgs.systemd}/bin/systemctl --user show-environment 2>/dev/null | \
          ${pkgs.gnugrep}/bin/grep -E '^(WAYLAND_DISPLAY|DISPLAY|XDG_SESSION_TYPE|XDG_RUNTIME_DIR|XDG_CURRENT_DESKTOP)=' | \
          ${pkgs.coreutils}/bin/sed 's/^/export /')"
        exec ${config.i18n.inputMethod.package}/bin/fcitx5
      fi
      sleep 0.5
    done
    # 兜底：超时也照常启动（fcitx5 自行处理无 Wayland 的情况）
    exec ${config.i18n.inputMethod.package}/bin/fcitx5
  '';
in
{
  programs.niri = {
    enable = true;
    package = niriWithSessionWrapper;
  };

  # Noctalia 及其 IPC 引擎（qs）进系统 PATH，方便 niri 快捷键和脚本调用。
  # 同时把 Noctalia 各面板常用的外部命令装进系统 PATH，这样即使手动在终端
  # 调试或脚本调用时也能找到它们。
  environment.systemPackages = let
    pythonWithDeps = pkgs.python3.withPackages (ps: with ps; [ numpy pillow ]);
  in with pkgs; [
    noctalia-shell
    noctalia-qs
    brightnessctl
    pamixer
    playerctl
    cliphist
    wl-clipboard
    wlr-randr
    networkmanager
    bluez
    imagemagick
    xdg-utils
    wlsunset
    ddcutil
    wget
    gnused
    gawk
    findutils
    procps
    matugen # 从壁纸生成 GTK/Qt/图标配色，Noctalia 外观同步依赖
    pythonWithDeps # scan-tones.py 依赖 (python3 + numpy + pillow)
  ];

  # Noctalia / 终端 / 中文 UI 所需的字体。
  fonts.packages = with pkgs; [
    adwaita-fonts
    lxgw-wenkai
    maple-mono.NF-CN
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # xdg-desktop-portal routing（对齐 SHORiN 的 niri-portals.conf：
  # 默认 gnome;gtk，文件选择走 gtk，录屏/截图走 gnome，密钥走 gnome-keyring）
  xdg.portal = {
    enable = lib.mkDefault true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
    };
  };

  # Noctalia / GTK 主题切换依赖 gsettings 写 dconf。
  programs.dconf.enable = true;

  # Fix graphical-session.target so systemd user services can use it
  systemd.user.targets.graphical-session = {
    unitConfig = {
      RefuseManualStart = false;
      StopWhenUnneeded = false;
    };
  };

  # polkit authentication agent
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome authentication agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # fcitx5 input method daemon.
  # Started as a systemd user service so it survives crashes and shares the
  # user's DBus session. Pulled in by graphical-session.target (activated by
  # the niri-session-wrapper Wayland session entry point above).
  #
  # ExecStart uses the NixOS-wrapped package (i18n.inputMethod.package =
  # fcitx5-with-addons), NOT the bare fcitx5 — otherwise addon engines like
  # fcitx5-rime never load (rime silently missing until a manual `fcitx5 -r`
  # from a shell that has the wrapped binary on PATH).
  systemd.user.services.fcitx5 = {
    description = "Fcitx5 input method";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${fcitx5Launch}/bin/fcitx5-launch";
      Restart = "always";
      RestartSec = 2;
      # home.sessionVariables (modules/home/fcitx5.nix) only reach login shells,
      # NOT systemd user services.  Without this, fcitx5-rime uses its default
      # user dir ~/.local/share/fcitx5/rime and never reads the custom configs
      # that home-manager writes to ~/.config/fcitx5/rime (schema_list,
      # rime_ice.custom.yaml), so rime deploys an empty/broken layout and
      # produces no candidates.
      Environment = [ "RIME_USER_DIR=%h/.config/fcitx5/rime" ];
    };
  };
}
