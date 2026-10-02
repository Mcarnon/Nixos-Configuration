# Hardware HAL: Gaomon（高漫）数位板 —— 已实测机型 M6。
#
# 为什么不用厂商驱动：高漫没有面向 Linux 的官方驱动，社区流传的那个包
# （/usr/lib/gaomontablet/huionCore）在 Wayland 下会去读 X11 的全局光标位置，
# niri 上表现为「笔重新落板时鼠标跳回同一个固定坐标」。OpenTabletDriver（OTD）
# 自带 M6 的配置（VID 0x256c，PID 0x0064 / 0x006d），笔定位 + 13 个辅助按键可用；
# 触摸环/滚轮 OTD 目前不解析，这部分无解。
#
# 上游模块 hardware.opentabletdriver 会做三件事：
#   - 安装 OTD 的 udev 规则（hidraw / uinput 走 logind ACL，故无需 hardware.uinput）
#   - 起用户级 otd-daemon（wantedBy = graphical-session.target，跟随 niri 会话）
#   - 把 hid-uclogic / wacom 加进 boot.blacklistedKernelModules
#
# 最后那条黑名单是**全局**副作用，也是本模块做成开关而不无条件启用的原因：一旦
# OTD 因为固件差异认不出板子，板子会完全没反应。退路是把
# hardware.opentabletdriver.blacklistedKernelModules 设为 [] 并关掉本开关，回到
# 内核自带的 hid-uclogic（0x256c:0x0064 属于 Huion 家族，插上即可当普通数位板用，
# 但没有压感曲线 / 按键映射 / 每应用 profile）。
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.hardware.gaomon;
in
{
  options.hardware.gaomon.enable = lib.mkEnableOption "Gaomon (高漫) tablet via OpenTabletDriver";

  config = lib.mkIf cfg.enable {
    hardware.opentabletdriver.enable = true;
  };
}
