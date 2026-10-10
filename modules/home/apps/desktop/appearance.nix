# Desktop look & feel: cursor theme + GTK icons/dark mode + 输入法桥接。
# 注意：Clavis 只重画自己的模板（btop/cava/yazi + 它自己的 colors.json），
# 不接管 GTK 的 gtk.css / settings.ini，所以【不用】 home-manager 的 gtk 模块
# 就不会和 Clavis 抢文件。基础外观走 dconf（DB，无文件冲突）；Clavis 设置中心的
# 深/浅色切换由 modules/home/desktop/clavis/bin/clavis-theme-sync 写
# org.gnome.desktop.interface color-scheme（需要 NixOS 侧的
# gsettings-desktop-schemas 才有这个 key）。
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # 光标主题/尺寸（本文件内只写一次，下面两处引用）。
  # ⚠️ 跨文件还有两个副本必须同名：home/niri/config.kdl 的 cursor{} 与
  # home/files/xsettingsd.conf 的 Gtk/CursorThemeName —— checks/niri-config.nix
  # 会校验那两处一致，这里的第三处靠人看（各文件注释里都写了）。
  #
  # 为什么是 Bibata-Modern-Ice（原来是 Breeze）：参考实现
  # （StatIndet/quickshell）自己**不钉任何光标主题** —— Clavis 的
  # theme.cursorTheme 默认空字符串，含义是「系统默认」，运行时取
  # `gsettings get org.gnome.desktop.interface cursor-theme`；作者自己的 dotfiles
  # 里同样没有 cursor{} 或 XCURSOR_THEME。既然「官方默认」= 跟着系统走，本仓库就
  # 把系统默认选成 Clavis 明确借鉴的三个项目（end-4/dots-hyprland、
  # caelestia-shell、DankMaterialShell）默认用的 Bibata，Material 风格也和这套
  # M3 配色一致。想换回来：这里改名字 + package（Breeze 是
  # pkgs.kdePackages.breeze / "breeze_cursors"），再同步 config.kdl 与
  # xsettingsd.conf 两处；或者直接在 Clavis 设置中心 → 主题 → 光标主题里选。
  cursorTheme = "Bibata-Modern-Ice";
  cursorSize = 24;
in
{
  # Wayland 光标：本仓库**不用** home-manager 的 gtk 模块（见文件头），而
  # home.pointerCursor 只是「把主题装进 profile + 写 ~/.icons/default/index.theme」，
  # 它写 dconf 的 cursor-theme/cursor-size 那条路挂在 gtk 模块上
  # （home-manager modules/misc/gtk/gtk3.nix：mkIf (gtk.enable && gtk.gtk3.enable)）——
  # gtk 模块没开时，dconf 里**根本没有** cursor-theme 这个键。后果：
  #   - GTK3/GTK4/libadwaita 读不到，落回 schema 默认（Adwaita）；
  #   - Clavis 的「系统默认」正是 `gsettings get ... cursor-theme`，于是它把
  #     Adwaita 写进 niri 的 cursor 片段；
  #   - 而本仓库 config.kdl 里钉的是另一个主题，X11/XWayland 应用又吃写死的
  #     XCURSOR_THEME（那条现已删除，改由 niri 从 cursor{} 派生）——
  #     同一个桌面三套光标，这就是「鼠标光标没统一」。
  # 所以下面 dconf 块把这两个键**显式**写出来（dconf 走 DB，不与 Clavis 抢文件），
  # 让它成为声明式默认的唯一去处；niri 那边由 config.kdl 的 cursor{} 兜底，
  # XCURSOR_THEME/SIZE 交给 niri 从 cursor{} 派生（config.kdl 的 environment{} 里
  # 刻意不再写死）。
  home.pointerCursor = {
    enable = true;
    name = cursorTheme;
    package = pkgs.bibata-cursors;
    size = cursorSize;
  };

  # 基础 GTK 外观（主题/图标/深色/输入法/光标）。动态配色交给 Clavis 的 matugen 产物。
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-system";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "Papirus-Dark";
        gtk-im-module = "fcitx";
        # 见上面 home.pointerCursor 的长注释：gtk 模块没开时这两个键只能自己写。
        # cursor-size 的 schema 类型是 i(int32)，Nix 整数默认就是 int32，直接给值。
        cursor-theme = cursorTheme;
        cursor-size = cursorSize;
      };
    };
  };

  # 启用 HM 的 fontconfig 支持，确保系统字体和用户 profile 字体都能被应用找到。
  fonts.fontconfig.enable = true;

  # fontconfig 用户级微调（抗锯齿/hinting + monospace 优先 Maple Mono NF）
  xdg.configFile."fontconfig/fonts.conf".source = ../../../home/files/fonts.conf;

  # Adwaita 图标主题是 Adwaita-Matugen 的继承源；必须存在，否则生成主题
  # 的图标会显示为缺失/错误图标（紫黑棋盘格）。
  # adw-gtk3（GTK 主题包）与 Papirus-Dark（初始图标主题）也由这里安装。
  # bibata-cursors 再显式装一遍：home.pointerCursor.package 只在它自己的代码路径里
  # 生效（GTK/X11 集成），这里保证主题一定落在 profile 的 share/icons 下 ——
  # niri 的 cursor{} 靠这个名字找 xcursor 主题，Clavis 的光标选择器也是扫
  # $XDG_DATA_DIRS/icons/*（scripts/theme/list_cursor_icon_themes.sh）。
  home.packages = with pkgs; [
    adw-gtk3
    papirus-icon-theme
    adwaita-icon-theme
    bibata-cursors
  ];
}