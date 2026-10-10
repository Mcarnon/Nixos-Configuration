# SDDM 登录界面 —— 主题是 thyx（QML），2026-10 起取代 ly。
#
# thyx 自带 NixOS 模块（inputs.thyx.nixosModules.default），它负责：
#   - services.displayManager.sddm.enable = true、theme = "thyx"
#   - extraPackages = [thyx] ++ [qtdeclarative qtmultimedia qt5compat qtsvg]
#     （主题 QML 只 import QtQuick / Controls / Layouts / Qt5Compat.GraphicalEffects，
#       视频背景还要 qtmultimedia，这四个够用；上游 VM 冒烟测试也是这套）
#   - fonts.packages = [thyx]（自带 Plus Jakarta Sans 可变字重）
# 所以这里只补 SDDM 自身需要的开关。
{
  inputs,
  ...
}:
{
  imports = [ inputs.thyx.nixosModules.default ];

  services.displayManager.sddm = {
    # 打开 thyx 模块自己（enable 默认 false）：它才会 enable sddm、theme = "thyx"、
    # 把主题和 Qt6 依赖塞进 extraPackages、装 Plus Jakarta Sans 字体。
    thyx.enable = true;

    # Wayland 模式下 SDDM 自己不合成，sddm-greeter 需要一个嵌套 compositor
    # （nixpkgs 默认 weston；thyx 上游的 flake check 同样开这个开关）。
    # 走 Wayland 就不会去起 Xorg 那一套 X11 会话。
    wayland.enable = true;
  };
}
