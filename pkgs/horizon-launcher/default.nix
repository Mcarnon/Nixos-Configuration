# Horizon Launcher：给上游 buildFHSEnv 的 bwrap 沙箱换一个私有 /tmp。
#
# 背景（报错现象）：
#   Could not complete game launch: bind holder control socket: permission denied
#   （诊断日志在 ~/.local/share/horizon-launcher/logs/launch-failure-*.log）
#
# 根因：forge-sa/horizon-nix 用 buildFHSEnv 打包启动器，所以启动器跑在
# bubblewrap 的 user namespace 里。这个命名空间只映射了当前 uid（1000），
# 宿主机的 root（uid 0）在命名空间内没有映射，stat 出来是 overflow uid
# 65534（nobody）。而 horizon 0.2.79 起，启动游戏前要先起一个 mod "holder"
# 进程、bind 一个私有控制 socket：
#
#   crates/horizon-mod-package/src/local_control/unix.rs
#     check_directory(): uid != geteuid() && (private || uid != 0) -> EACCES
#
# socket 目录优先放 $XDG_RUNTIME_DIR，不合适就退回 /tmp。检查会逐级 stat
# 父目录并要求「属于自己，或属于 root」；沙箱里 /run、/run/user、/tmp 都是
# 宿主 bind 进来的 root 家当，一律显示成 65534，于是两个候选都被否掉，
# 连 mkdir/bind 都没机会执行，Play 直接失败。
#
# 修法：bwrap 自己建的 tmpfs（沙箱的 "/" 就是这样）属于当前 uid，所以把
# /tmp 也换成 bwrap 的 tmpfs（extraBwrapArgs 追加在 auto_mounts 之后，能覆盖
# 宿主 /tmp 的 bind）。这样 /tmp 属于 uid 1000、权限 0755，check_directory
# 通过，holder 的控制 socket 落在沙箱私有的 /tmp 里，游戏正常启动。
#
# 代价：沙箱内看不到宿主 /tmp，包括 /tmp/.X11-unix。本机是 niri/Wayland 且
# Horizon 原生走 Wayland，X11 回退用不到；真需要时再在 extraBwrapArgs 里
# 把 X socket 转接进来。
#
# 回退条件：上游修好即可删掉本目录，gui.nix 改回
# inputs.horizon.packages.<system>.default（比如上游不再假设 st_uid == 0，
# 或者在检查前先尝试 mkdir/bind）。
{
  callPackage,
  buildFHSEnv,
  source, # inputs.horizon：flake 源树，含 package.nix / source.json / assets/
}:

let
  # 包一层 buildFHSEnv：其余参数原样透传，只多挂一个私有 /tmp。
  buildFHSEnvWithPrivateTmp =
    fhsArgs:
    buildFHSEnv (
      fhsArgs
      // {
        extraBwrapArgs = (fhsArgs.extraBwrapArgs or [ ]) ++ [
          "--tmpfs"
          "/tmp"
        ];
      }
    );
in
callPackage "${source}/package.nix" {
  buildFHSEnv = buildFHSEnvWithPrivateTmp;
}
