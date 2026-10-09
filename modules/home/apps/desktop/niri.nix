# Link niri's KDL config to ~/.config/niri.
# Shared config files are linked individually; the machine-specific output
# config (niri-hardware.kdl) is passed in from the host.
#
# 例外是**主配置** config.kdl：它必须是一份可写副本，不能是 store 软链，
# 见下面 niriConfigSrc 的说明。
{
  config,
  pkgs,
  lib,
  hostPath,
  ...
}:
let
  # niri 主配置的源文件。运行时它会以「可写副本」的形式出现在
  # ~/.config/niri/config.kdl（内容仍 100% 声明式，每次 switch 从 store 覆盖）。
  #
  # 为什么不能像其余 .kdl 一样做成软链：Clavis 的 niri 集成
  # （<clavis>/scripts/system/niri_config.py）在写**任何**片段之前都会先
  # safe_target(主配置)，而那个检查无条件拒绝软链：
  #     Symbolic links are read-only: /home/<user>/.config/niri/config.kdl
  # 连「include 早就写好、只需要新建片段文件」的路径也过不去。做成软链的后果是
  # 读没问题、写全失败（GUI 看起来是好的，点下去才弹上面这行错误）：
  #   - 设置中心 → 壁纸 → Overview integration → Set up（写 clavis/layer-rules.kdl）
  #   - 设置中心 → 主题 → 光标主题 / 光标尺寸（写 clavis/cursor.kdl）
  #   - 设置中心 → 通用 → 透明与模糊（写 clavis/effects.kdl）
  # 换成副本后这三条链路才真的能改东西；代价是本文件被 Clavis 追加过的 include
  # 不会留存（下次 switch 覆盖回去），所以六个 clavis/*.kdl 的 include 必须写在
  # 源文件里。
  niriConfigSrc = ../../../home/niri/config.kdl;
in
{
  xdg.configFile = {
    "niri/binds.kdl".source = ../../../home/niri/binds.kdl;
    "niri/blur.kdl".source = ../../../home/niri/blur.kdl;
    "niri/startup.kdl".source = ../../../home/niri/startup.kdl;
    "niri/windowrule.kdl".source = ../../../home/niri/windowrule.kdl;
    "niri/supertab.kdl".source = ../../../home/niri/supertab.kdl;
    "niri/clavis-static.kdl".source = ../../../home/niri/clavis-static.kdl;
    "niri/niri-hardware.kdl".source = hostPath + "/niri-hardware.kdl";
  };

  # config.kdl 的可写副本（见 niriConfigSrc）。
  #
  # 排序：entryBefore linkGeneration —— 让副本在 home-manager 清理/重建链接**之前**
  # 就位。两个好处：目标始终存在（不会出现「旧软链被清理掉、副本还没写」的空窗，
  # niri 正在监视这个文件），而且清理阶段看到的是普通文件（cleanOldGen 只删
  # 「还指回 store 的链接」，见 home-manager modules/files.nix），不会被误删。
  # cmp 相同就不动：避免每次 switch 都换 mtime，让 niri 白重载一次配置。
  home.activation.niriMainConfigCopy = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    src=${niriConfigSrc}
    dst="''${HOME:-/home/mccarnon}/.config/niri/config.kdl"
    if [ ! -f "$dst" ] || [ -L "$dst" ] || ! cmp -s "$src" "$dst"; then
      mkdir -p "$(dirname "$dst")"
      tmp="''${dst}.home-manager-new"
      install -m644 "$src" "$tmp"
      mv -f "$tmp" "$dst"
    fi
  '';

  # 注意：Clavis 托管的片段（effects / cursor / layer-rules / binds / outputs /
  # minimize-animation）刻意【不】在这里声明。它们由 Clavis 自己写进
  # ~/.config/niri/clavis/，是运行时生成的普通文件；config.kdl 里已经用
  # `include optional=true` 预留了位置。做成 home.file 会让 HM 把它们变成指向
  # /nix/store 的只读软链，Clavis 每次写片段都会失败（safe_target 同样拒绝软链）。
  # 其中 layer-rules.kdl / cursor.kdl 由 modules/home/desktop/clavis 用 activation
  # 种成可写副本，理由见那边。
}
