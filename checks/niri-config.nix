# niri KDL config validation (no VM, no network: just `niri validate`).
#
# Why: home/niri/*.kdl is a set of `include`s parsed only at niri startup, so a
# typo (e.g. `spawn-sh` outside `binds {}`) survives `home-manager switch` and
# only shows up as a black screen / ignored keybinding after the next login.
# `niri validate` catches it in CI instead.
#
# Clavis 会往 ~/.config/niri/clavis/ 写 6 个托管片段（outputs / cursor /
# layer-rules / effects / minimize-animation / binds —— 抄
# scripts/system/niri_config.py:24 的 FRAGMENTS 元组，不是抄过期文档的表格），
# 全部由 `include optional=true` 引入：所以这里不需要 stub 什么"运行时生成
# 物"，配置是全静态的。
#
# niri-hardware.kdl 不再 stub —— 它现在只含注释，是合法 KDL，而且下面的
# 「分辨率必须保持默认」断言必须对着**真文件**跑才有意义（对 stub 跑等于没跑）。
{
  pkgs,
}:
pkgs.runCommand "niri-config-validate"
  {
    nativeBuildInputs = [ pkgs.niri ];
  }
  ''
    set -euo pipefail

    src=${../home/niri}
    work=$TMPDIR/niri
    mkdir -p "$work"
    cp "$src"/*.kdl "$work/"

    # niri-hardware.kdl is per host (hosts/<host>/niri-hardware.kdl) and is a hard
    # `include`, so copy the real one for the host this flake is checked against
    # instead of a stub. Only `laptop` exists; keep the guard so a second host
    # can't silently fall back to a stub and void the mode assertion below.
    hardware=${../hosts/laptop}/niri-hardware.kdl
    if [ ! -f "$hardware" ]; then
      echo "niri-config check: missing $hardware (update this check's host)" >&2
      exit 1
    fi
    cp "$hardware" "$work/niri-hardware.kdl"

    niri validate -c "$work/config.kdl"

    # ── 桌面壳调用方式 ───────────────────────────────────────────────────────
    # 外壳动作一律 `key ipc call <target> <method>`：key 的 wrapper 钉死了
    # PATH/QML_IMPORT_PATH/XDG_CONFIG_DIRS，niri 的 spawn 直连 PATH。
    # 留断言免得以后有人抄成裸 `qs`/`quickshell ipc`（会话 PATH 里没有 qs，
    # 按键会静默失败）或把已删除的 iNiR 抄回来。
    if grep -rnE '(^|[^-a-z])(inir) ' "$work"/*.kdl; then
      echo "home/niri/*.kdl still calls the removed iNiR shell" >&2
      exit 1
    fi
    if grep -rnE 'spawn(-sh)? "?(qs|quickshell)"?' "$work"/*.kdl; then
      echo "home/niri/*.kdl calls quickshell directly; use 'key ipc call ...'" >&2
      exit 1
    fi
    if ! grep -q '"key" "ipc" "call"' "$work/binds.kdl"; then
      echo "home/niri/binds.kdl has no 'key ipc call' bindings" >&2
      exit 1
    fi

    # ── Clavis 托管片段必须是 optional，且必须全部在 include 链里 ───────────
    # 片段由外壳自己写（用户点开对应设置页时才生成）。写成硬 include 的话，
    # 登录前的那次 niri 启动会因缺文件直接失败 —— 也就是"第一次开机黑屏"。
    #
    # 缺 include 则是另一个方向的静默故障：上游
    # docs/architecture/config-isolation.md 明确「安装只部署程序与只读资源，
    # 启动、页面加载、文件监听均不初始化片段」，设置界面只负责"创建文件 +
    # 追加缺失的顶层 include"。片段没进 include 链时，磁盘上永远不会有这个
    # 文件，设置页于是既不报错也不生效 —— 表现为「分辨率/光标/背景/快捷键这几
    # 个设置页全是死的」。所以逐个断言，不只看 effects.kdl。
    #
    # 名字和数量以代码为准，不以那份文档的表格为准 —— 表格只有 4 行且第 14 行
    # 还明说"没有内置 outputs 片段"，而 scripts/system/niri_config.py:24 的
    # FRAGMENTS 元组有 6 个。下面这个列表抄的就是那个元组，改一个改两个。
    for fragment in outputs cursor layer-rules effects minimize-animation binds; do
      if ! grep -q "include optional=true \"clavis/$fragment.kdl\"" "$work/config.kdl"; then
        echo "config.kdl must include \"clavis/$fragment.kdl\" with optional=true" >&2
        exit 1
      fi
    done
    # 任何 clavis/ 片段都不许退化成硬 include（会挡住 niri 启动）。
    if grep -nE '^[[:space:]]*include[[:space:]]+"?clavis/' "$work/config.kdl"; then
      echo "config.kdl has a non-optional clavis include; it must be optional=true" >&2
      exit 1
    fi

    # ── 外壳依赖的环境变量必须非空 ──────────────────────────────────────────
    # environment {} 只影响 niri 拉起的进程；systemd user unit 里的同名变量
    # 由 modules/home/desktop/clavis 负责（unitEnvironment）。两处缺一个，
    # 外壳就退回空图标（紫黑棋盘格）或不画背景。
    #
    # XDG_DATA_DIRS 在这条列表里不是凑数：Clavis 的启动器/dock/spotlight 图标
    # 走系统图标主题解析（ApplicationService.qml 的 Quickshell.iconPath），而
    # NixOS 的图标主题只存在于系统 profile 的 share/icons。没有它 → 整个图标
    # 主题不可见 → 图标大面积空白且零报错。
    for name in QS_ICON_THEME XDG_DATA_DIRS QT_QPA_PLATFORMTHEME_QT6 ELECTRON_OZONE_PLATFORM_HINT XMODIFIERS; do
      value=$(sed -nE "s/^[[:space:]]*''${name}[[:space:]]+\"([^\"]+)\".*/\1/p" "$work"/*.kdl | tail -n1)
      if [ -z "$value" ]; then
        echo "niri config does not define $name with a non-empty value" >&2
        exit 1
      fi
      echo "niri environment: $name=$value"
    done

    # ── 分辨率必须保持 niri 默认 ────────────────────────────────────────────
    # 要求真正生效的 output 块（hosts/<host>/niri-hardware.kdl）里没有 mode。
    # 注释掉的不算，所以先剥注释再查。Clavis 自己托管的
    # clavis/outputs.kdl 是用户通过设置页选的，不在这里管。
    effective=$(sed 's://.*::' "$work/niri-hardware.kdl")
    if printf '%s' "$effective" | grep -qE '^[[:space:]]*mode[[:space:]]'; then
      echo "niri-hardware.kdl pins an output mode; the panel must use niri's default" >&2
      exit 1
    fi

    touch $out
  ''
