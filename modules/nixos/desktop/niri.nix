# niri compositor (login manager lives in ./ly.nix)
{
  config,
  pkgs,
  lib,
  inputs,
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
  # `WantedBy=graphical-session.target`（clavis-shell, fcitx5, polkit）永远
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
      paths = [
        pkgs.niri
        niriSessionWrapperScript
      ];
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
  # 症状等同"输入法没加载"）。
  fcitx5Launch = pkgs.writeShellScriptBin "fcitx5-launch" ''
    PATH="${
      lib.makeBinPath [
        pkgs.systemd
        pkgs.coreutils
        pkgs.gnugrep
      ]
    }"
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

  # Clavis 的 `key` 命令（IPC / 剪贴板 / 录屏 / sysmon）进系统 PATH：niri 键位、
  # 壁纸脚本和 Clavis 自己都用裸 `key` 调用，必须在任何登录 shell 的环境里可见。
  # pkgs.clavisShell / pkgs.m3shapes 不需要 PATH 入口 —— 它们只提供 QML 资源，
  # 由 pkgs.keyCli 的 wrapper 注入 QML_IMPORT_PATH。
  # 同时把各面板常用的外部命令装进系统 PATH，这样即使手动在终端
  # 调试或脚本调用时也能找到它们。
  environment.systemPackages =
    let
      pythonWithDeps = pkgs.python3.withPackages (
        ps: with ps; [
          numpy
          pillow
        ]
      );
    in
    with pkgs;
    [
      pkgs.keyCli
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
      pythonWithDeps # scan-tones.py 依赖 (python3 + numpy + pillow)
      # gsettings-desktop-schemas 提供 org.gnome.desktop.interface color-scheme，
      # Clavis 的 scripts/theme/set_system_color_scheme.sh 写它来切 GTK 深浅色。
      # 缺 schema 时 dconf 写入静默失败，GTK 应用不会跟着 Clavis 切主题。
      gsettings-desktop-schemas
    ];

  # Clavis / 终端 / 中文 UI 所需的字体。
  #   - material-symbols：Clavis 的 Components/MaterialSymbol.qml 固定请求
  #     "Material Symbols Rounded"（Common/Fonts.qml 里写死），缺了整套图标变豆腐块。
  #   - lxgw-wenkai-screen / jetbrains-mono：Clavis 的默认 UI / 等宽字体族名
  #     （Common/Fonts.qml: "LXGW WenKai GB Screen" / "JetBrainsMono Nerd Font"）。
  #     缺字体不会崩，resolveFamily 会退回 generic fallback，但排版会变。
  #     用屏幕版（-screen）而不是 lxgw-wenkai：GB Screen 字体实际没有单独的
  #     包，Clavis 请求的族名由下面的 fontconfig 别名映射到 "LXGW WenKai Screen"。
  fonts.packages = with pkgs; [
    adwaita-fonts
    lxgw-wenkai-screen
    maple-mono.NF-CN
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    material-symbols
  ];

  # Clavis 的 Common/Fonts.qml 硬编码 "LXGW WenKai GB Screen"，但发布的只有
  # "LXGW WenKai Screen"（lxgw-wenkai-screen）。别名让 Qt/文本栈在请求 GB Screen
  # 时命中同一个族，避免回退到 Noto Sans CJK 造成 UI 字体不统一。
  fonts.fontconfig.localConf = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <match target="pattern">
        <test name="family" compare="eq">
          <string>LXGW WenKai GB Screen</string>
        </test>
        <edit name="family" mode="prepend" binding="strong">
          <string>LXGW WenKai Screen</string>
        </edit>
      </match>
    </fontconfig>
  '';

  # Clavis 的键盘面板要读 evdev 键盘节点。logind 默认只把节点交给 root，
  # 所以带键盘背光的设备在 `key doctor` 里会报 keyboard 不可用。
  # 规则与上游 packaging/udev/71-clavis-keyboard-leds.rules 逐字一致：只给
  # 「带 LED 能力的键盘」打 uaccess（对应 Arch 的 key-cli-keyboard-access
  # 分包），而不是放开全部输入设备。
  #
  # 注意 extraRules 的类型是 `types.lines`（单个字符串），不是字符串列表；
  # 传 list 会报 "not of type `strings concatenated with \"\n\"'"。
  services.udev.extraRules = lib.mkAfter (''
    SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_KEYBOARD}=="1", ATTRS{capabilities/led}=="?*", ATTRS{capabilities/led}!="0", TAG+="uaccess"
  '');

  # 可选授权：给 key-cpu-power 开 cap_dac_read_search，让 Clavis 能读受保护的
  # RAPL 能耗计数器（Intel 笔记本的 CPU 功率读数）。没有它 CPU 占用率照常可用，
  # 只有「功率」那一项显示 unavailable。
  #
  # 为什么放在 systemd 而不是 build 阶段：目标在 /nix/store 里，路径每次升级都变，
  # 任何写死路径的声明式做法都会在下次 nixos-rebuild 后指向不存在的文件。
  # 这里的路径是求值时展开的当前 hash；setcap 失败不致命（|| true）。
  systemd.services.clavis-key-cpu-power-access = {
    description = "Grant key-cpu-power read access to RAPL energy counters";
    wantedBy = [ "multi-user.target" ];
    before = [ "graphical-session.target" ];
    after = [ "nix-store-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # systemd 的 ExecStart 不经过 shell，所以 `|| true` 必须显式借一个 shell。
      # lib.escapeShellArgs 只接受一个参数（list 或 string），写成两个参数会
      # 直接求值失败，所以整个 argv 必须放进同一个 list。
      ExecStart = lib.escapeShellArgs [
        # pkgs.runtimeShell is the bin *directory* (/nix/store/...-bash/bin),
        # not the interpreter -- appending /bin/bash to it yields the
        # nonsensical `.../bin/bash/bin/bash` ExecStart that systemd rejects.
        "${pkgs.bash}/bin/bash"
        "-c"
        ''
          ${pkgs.libcap}/bin/setcap cap_dac_read_search=ep \
            ${pkgs.keyCli}/libexec/key-cli/key-cpu-power || true
        ''
      ];
    };
  };

  # xdg-desktop-portal routing（对齐 SHORiN 的 niri-portals.conf：
  # 默认 gnome;gtk，文件选择走 gtk，录屏/截图走 gnome，密钥走 gnome-keyring）
  xdg.portal = {
    enable = lib.mkDefault true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
    };
  };

  # Clavis 的主题模式同步脚本写 dconf 的 org.gnome.desktop.interface color-scheme
  # 来切 GTK 深浅色（见 modules/home/desktop/clavis/bin/clavis-theme-sync）。
  programs.dconf.enable = true;

  # 把 gsettings schema 目录挂进 XDG_DATA_DIRS。
  #
  # nixpkgs 现在把 schema 装到 $out/share/gsettings-schemas/<name>/glib-2.0/schemas，
  # 而不是 glib 默认会搜的 $out/share/glib-2.0/schemas（gsettings-desktop-schemas
  # 的 preInstall 注释就写着 "later moved by glib's setup hook"）。所以光把包列进
  # environment.systemPackages 不够：/run/current-system/sw/share/glib-2.0 里没有
  # 任何 schema，gsettings 一律报 "No schemas installed"。
  #
  # NixOS 自己的 GNOME/Budgie/Cinnamon/… 模块靠 environment.extraInit 补这一刀
  # （见 gnome.nix:263、budgie.nix:142…），本机跑 niri/Clavis，不经过其中任何一个，
  # 于是整条深浅色链路是断的：
  #   - clavis-theme-sync 的 `gsettings set color-scheme` 静默失败（脚本里 || true），
  #     dconf 一直停在 prefer-system；
  #   - xdg-desktop-portal-gnome 读不到 org.gnome.desktop.interface，Appearance 端口
  #     不发 AppearanceChanged，fcitx5（classicui 靠 portal 判断深浅色，
  #     见 libclassicui 里的 org.freedesktop.appearance/color-scheme）不换主题；
  #   - GTK4/libadwaita、Chromium 系直接读 dconf 的也读不到。
  #
  # 用 sessionVariables 而不是 extraInit：前者由 PAM 在登录时写进整个会话（含
  # systemd --user 与它拉起的 portal/fcitx5），extraInit 只影响登录 shell。
  # mkAfter 只是保证不覆盖别处（如 display-manager 模块）的 XDG_DATA_DIRS；
  # 它会排在 profileRelativeSessionVariables 生成的 /run/current-system/sw/share
  # 之前（system-environment.nix 里 sessionVariables 先于 suffixedVariables 合并），
  # 顺序对 schema 查找无影响。
  environment.sessionVariables.XDG_DATA_DIRS = lib.mkAfter [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
  ];

  # Fix graphical-session.target so systemd user services can use it
  systemd.user.targets.graphical-session = {
    unitConfig = {
      RefuseManualStart = false;
      StopWhenUnneeded = false;
    };
  };

  # polkit authentication agent
  security.polkit.enable = true;
  # pkexec 需要 setuid root 才能给 GUI 提权（gparted 的菜单条目就是
  # `pkexec --disable-internal-agent gparted`）。NixOS 默认不装任何 setuid
  # 二进制（store 里也放不了 setuid），不开这个开关，pkexec 会直接报
  # "pkexec must be setuid root" 并以 127 退出——菜单点了没任何反应。
  security.polkit.enablePkexecWrapper = true;
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
