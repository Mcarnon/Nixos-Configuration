# FlClash 特权 helper —— TUN 模式需要的 root Core。
#
# FlClash 的 GUI 在用户态跑；TUN 需要的 root 权限由它打包的
# `FlClashHelperService` 承担（services/helper/src/service/linux.rs）：
#
#   - 它在 /run/flclash/helper.sock 上跑一个 HTTP 服务（warp），只接受对端
#     uid == FLCLASH_HELPER_OWNER_UID 的连接（peer cred 判定，不看 socket
#     属组），收到 /start 后自己拉起同目录的 FlClashCore，并在 pre_exec 里
#     setresuid(uid, 0, 0) —— real uid 交还用户、euid 保持 root，Core 既能建
#     TUN 又能把流量/规则记在用户名下。
#   - 拉起前会校验 FlClashCore 的 SHA256（编译期 CORE_SHA256，与同目录
#     manifest.json 的 coreSha256 一致，即官方 .deb 里的那一对）。
#
# 上游初次启动时由 GUI 通过 pkexec 跑 `FlClashHelperService install`，把 unit
# 写进 /etc/systemd/system。NixOS 的 /etc 是 activation 生成的，让 GUI 往里面
# 塞 unit 会和声明式配置打架（重建即丢、不可审计），所以这里直接声明同名
# unit。这样 GUI 的 registerService() 在 `helperClient.readiness()` 拿到 ok 后
# 直接返回 AuthorizeCode.none，pkexec 那条路径根本不会被走到。
#
# 三个必须对齐的硬约束（对不上 helper 会被判定为 not ready，静默回落到用户态
# Core，TUN 开关灰掉）：
#   1. unit 名必须是 `flclash-helper`（同时也避免 /etc 里出现第二个同名 unit）。
#   2. ExecStart 必须是同一个包的 `$out/opt/FlClash/FlClashHelperService`：
#      helper 沿自身目录找 FlClashCore 和 manifest.json，GUI 还会把 ping 返回
#      的路径和 `dirname(自身可执行文件)` 逐字比对。所以系统单元和用户态 GUI
#      必须来自同一个 pkgs.flclash（本仓库两边都用 overlay 里的那个 derivation）。
#   3. FLCLASH_HELPER_OWNER_UID/GID 必须存在且非 0：helper 拒绝 uid 0（否则等于
#      没人能连），也拒绝非数字。
#
# 不要给这个 unit 加 PrivateTmp/ProtectSystem/ProtectHome 之类的沙箱：Core 要在
# 宿主的 /tmp 下建 /tmp/FlClashSocket_<id>.sock（属主要能连），还要动
# nftables/iptables 规则和路由表。
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.flclash-helper;

  # 属主就是「被授权驱动 root Core 的本地账号」。GUI 以一个普通用户身份跑，
  # 只有这个 uid 能穿过 peer cred 检查。
  #
  # NixOS 的 isNormalUser 默认不写死 uid（activation 用 useradd 动态分配，本机
  # 就是 1000），所以这里优先用声明式 uid，没有则用 cfg.uid 回退；两者不一致会
  # 在 PreStart 里直接报错，而不是让 helper 起来后静默拒绝 GUI 的连接。
  declaredUid = config.users.users.${cfg.user}.uid;
  ownerUid = if declaredUid != null then declaredUid else cfg.uid;

  # helper 的 Group= 用的是属主的**主组**（上游 install 里 `id -g` 的结果），
  # 同时也是 helper.sock 的属组（mode 0660）。NixOS 的 ids.gids 是唯一能在
  # 求值期拿到数字 gid 的来源；users 组固定为 100。
  ownerGid = config.ids.gids.${cfg.group} or null;
in
{
  options.services.flclash-helper = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "mccarnon";
      description = "被授权驱动 root Core 的本地账号（helper.sock 的 peer uid）。";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = ''
        当 `users.users.<user>.uid` 没有声明式赋值时使用的 uid 回退值。
        NixOS 对 `isNormalUser` 动态分配 uid（uid_min=1000），单用户机器上
        就是 1000。真正的值会在 unit 的 PreStart 里和 `id -u` 比对。
      '';
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "helper 进程的主组 / helper.sock 的属组，必须是 NixOS ids 表里的组。";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.flclash;
      defaultText = lib.literalExpression "pkgs.flclash";
      description = "提供 FlClashHelperService / FlClashCore / manifest.json 的包。";
    };
  };

  config = {
    assertions = [
      {
        assertion = declaredUid == null || declaredUid == ownerUid;
        message = "services.flclash-helper: ${cfg.user} 的声明式 uid 和配置的 ${toString ownerUid} 不一致。";
      }
      {
        assertion = ownerGid != null;
        message = "services.flclash-helper.group: ${cfg.group} 不在 config.ids.gids 里，拿不到数字 gid。";
      }
    ];

    systemd.services.flclash-helper = {
      description = "FlClash Helper starts the FlClash Core with the privileges TUN mode needs.";

      # 与上游 unit 保持一致：TUN 规则走 nftables / iptables，起太早会找不到表。
      after = [
        "nftables.service"
        "iptables.service"
      ];
      wantedBy = [ "multi-user.target" ];
      startLimitIntervalSec = 60;
      startLimitBurst = 5;

      environment = {
        FLCLASH_HELPER_OWNER_UID = toString ownerUid;
        # ownerGid 为 null 时上面的 assertion 会先失败，这里的 0 只是占位。
        FLCLASH_HELPER_OWNER_GID = if ownerGid == null then "0" else toString ownerGid;
      };

      # helper 只认环境变量里的 uid，拿不到就起不来；uid 对不上则每个连接都被
      # peer cred 拒掉，表现成 GUI 一直报 helper 未就绪。两者都在启动期喊出来。
      preStart = ''
        actual=$(${pkgs.coreutils}/bin/id -u ${cfg.user})
        if [ "$actual" != "${toString ownerUid}" ]; then
          echo "flclash-helper: ${cfg.user} 的实际 uid 是 $actual，unit 里写的是 ${toString ownerUid}" >&2
          exit 1
        fi
      '';

      serviceConfig = {
        Type = "simple";

        # 上游写的是 systemd 转义过的带引号路径（见 quoted_unit_argument）；
        # store 路径没有空格/引号/%，直接引用即可。
        ExecStart = "${cfg.package}/opt/FlClash/FlClashHelperService";

        Group = cfg.group;

        # helper 只 chmod socket，不建目录；/run 是 tmpfs，必须由 systemd 建。
        RuntimeDirectory = "flclash";
        RuntimeDirectoryMode = "0755";

        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
