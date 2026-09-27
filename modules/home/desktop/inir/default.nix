# iNiR — niri 的 Quickshell 桌面外壳（取代 Clavis / Noctalia）。
#
# 本模块负责：
#   - 走上游 flake：导入 `inputs.inir.homeManagerModules.default`，于是
#     programs.inir 的打包、服务、dbus 名称都由上游维护，本机不重复实现。
#     programs.inir.package 的默认值是 pkgs.callPackage <inir>/nix/package.nix，
#     也就是用【本 flake 的 nixpkgs】构建（上游自己 pin 的 nixpkgs 只在
#     `nix build .#inir` 那条路上用到）。
#     万一上游 package.nix 依赖的某个 python 包在本机 nixpkgs 里缺失，
#     逃生口是显式指定 programs.inir.package = inputs.inir.packages.${system}.inir。
#   - systemd 用户服务 inir.service：上游已按 niri 生命周期挂载
#     （PartOf/Requisite/After = niri.service，WantedBy = niri.service），
#     Type=dbus + BusName=org.kde.StatusNotifierWatcher（托盘归它）。
#     这里只做两处本机必要的加固：
#       * ExecStart 换成 inir-session-env 包装，补齐 Wayland socket
#         （home/niri/startup.kdl 的 import-environment 是第一道，这是第二道；
#         没有它就是"切壳之后桌面全黑"）；
#       * StartLimitIntervalSec = 0，避免崩溃循环被 start-limit 打死后
#         永久黑屏且没人自愈（Restart=on-failure 会一直重试）。
#   - extraPackages：iNiR 的 wrapper 自带 quickshell/cliphist/wl-clipboard/
#     grim/slurp/playerctl/ffmpeg/tesseract/wf-recorder/... 一整套运行时，但那份
#     清单是【构建时按上游 pin 的 nixpkgs】用 optional 属性挑的，上游那边恰好
#     缺哪个包，我们这边就少了哪个工具且不报错。所以这里把外壳一定会 fork
#     的少数几个显式钉住（用本机 nixpkgs 的版本）。
#   - 「首次部署种子、之后永不覆盖」的可写文件：qt6ct（GUI 里保存要写回自己）
#     和 kitty 的 current-theme.conf（iNiR 第一次按壁纸生成配色之前的静态兜底，
#     否则 kitty.conf 的 include 会报错）。
#   - 默认壁纸 + 用户头像（选择器/设置界面直接能看到）。
#
# 已由 iNiR 自己接管、不再需要自建的东西：壁纸选择器/随机/在线浏览、壁纸轮换、
# 壁纸取色主题（gtk3/gtk4/fuzzel/kde/firefox/steam/kitty/foot/starship/btop/
# yazi/lazygit/oh-my-posh + OSC 序列）、剪贴板历史、电源/锁屏/音量面板、
# 系统监视（原来的 keytop）、AI 侧栏、命令面板。
inputs: {
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [ inputs.inir.homeManagerModules.default ];

  programs.inir = {
    enable = true;
    # 上游只支持 niri；置 false 可以只建 unit 不自动挂 niri.service。
    service.compositor = "niri";
    # iNiR wrapper 的 PATH 里【可能】没有、但它一定会 fork 出来用的东西。
    extraPackages = with pkgs; [
      brightnessctl # 亮度面板
      ddcutil # 外接显示器亮度
      pamixer # 音量/静音面板后端
      wtype # 锁屏密码输入
      satty # 截图标注
    ];
  };

  let
    home = config.home.homeDirectory;

    # 必须是 writeShellScriptBin（产出带 /bin 的目录）：这脚本进 home.packages，
    # 而 home-manager-path 用 buildEnv 合并 sessionPath，file 类型的 store path
    # 会直接让 buildEnv 报 "is a file and cannot be added to a directory"。
    sessionEnv = pkgs.writeShellScriptBin "inir-session-env" (builtins.readFile ./bin/inir-session-env);

    # 「首次部署种子、之后永不覆盖」的可写文件。
    # 刻意不用 home.file：它只会把 /nix/store 里的只读文件软链过去，而这些文件
    # 都要被应用自己回写（qt6ct 的 GUI 保存、iNiR 的配色生成）—— 指向 store 的
    # 软链两者都写不进去。
    seedFile =
      name: src:
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        target="''${HOME:-${home}}/${name}"
        if [ ! -e "$target" ]; then
          install -Dm644 ${src} "$target"
          echo "inir: seeded ${name}"
        fi
      '';

    # 种子配置 ~/.config/inir/config.json = 上游 defaults/config.json 加上本机
    # 需要的两处修正（用 jq 在构建期改，构建产物，不是 IFD）：
    #   * terminals.starship = false —— 我们的 starship.toml 由 home-manager
    #     声明式管理（只读 store 软链），iNiR 的 starship 模板会试图往里追加
    #     format 行，写不进去；更糟的是它和 kitty/foot/btop 共用一次生成进程，
    #     一个 terminal 抛错就可能让后面的都不落地。直接关掉最省事。
    #   * 其余保持上游默认（壁纸取色、面板、mascot 等全部开箱可用）。
    # 上游 installer 也是「把 defaults 拷成用户配置」的做法；种子不加 force，
    # 用户之后在设置界面/手改的偏好必须能活过下一次 home-manager switch。
    inirConfigSeed = pkgs.runCommand "inir-config.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
        src = "${config.programs.inir.package}/share/quickshell/inir/defaults/config.json";
      } ''
      jq '.appearance.wallpaperTheming.terminals.starship = false' "$src" > "$out"
    '';
  in
  {
    # 用包装脚本替换上游的 ExecStart（其余 unit 设置保持上游原样）。
    systemd.user.services.inir = {
      Unit.StartLimitIntervalSec = lib.mkForce 0;
      Service.ExecStart = lib.mkForce "${sessionEnv}/bin/inir-session-env ${lib.getExe config.programs.inir.package} run --session";
    };

    # inir-session-env 本身要在 PATH 里（niri 快捷键/调试脚本可能直接调）。
    # wtype/qt6ct/qtsvg 原来是靠旧桌面壳模块的 sessionPath 带进来的。
    home.packages = with pkgs; [
      sessionEnv
      wtype
      qt6Packages.qt6ct
      qt6Packages.qtsvg # Qt SVG 图像插件（壁纸/图标里的 .svg）
    ];

    home.activation.inirSeedQt6ct = seedFile ".config/qt6ct/qt6ct.conf" ../../../../home/files/qt6ct/qt6ct.conf;
    home.activation.inirSeedConfig = seedFile ".config/inir/config.json" inirConfigSeed;
    # iNiR 的终端配色写 ~/.config/kitty/themes/current-theme.conf，kitty.conf
    # include 它；首次部署（iNiR 还没跑过配色生成）时先种一份静态兜底。
    home.activation.inirSeedKittyTheme = seedFile ".config/kitty/themes/current-theme.conf" ../../../../home/files/kitty/current-theme.conf;

    # 默认壁纸 + 用户头像。
    home.file."Pictures/Wallpapers/wallhaven-d88d53.png".source = ../../../../wallpapers/wallhaven-d88d53.png;
    home.file.".face".source = ../../../../wallpapers/wallhaven-d88d53.png;

    # 输入法 / Qt 主题变量（Qt6 应用与 fcitx5 需要）。
    home.sessionVariables = {
      "QT_QPA_PLATFORM" = "wayland;xcb";
      "QT_QPA_PLATFORMTHEME" = "qt6ct";
      "QT_AUTO_SCREEN_SCALE_FACTOR" = "1";
      "XMODIFIERS" = "@im=fcitx";
      "GTK_IM_MODULE" = "fcitx";
      "QT_IM_MODULE" = "fcitx";
    };
  }
}
