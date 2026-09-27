# niri KDL config validation (no VM, no network: just `niri validate`).
#
# Why: home/niri/*.kdl is a set of `include`s parsed only at niri startup, so a
# typo (e.g. `spawn-sh` outside `binds {}`) survives `home-manager switch` and
# only shows up as a black screen / ignored keybinding after the next login.
# `niri validate` catches it in CI instead.
#
# Clavis 只往 ~/.config/niri/ 写一个片段（clavis/effects.kdl，模糊/xray
# 开关），而且是 `include optional=true` 引入的：所以这里不需要 stub 什么
# "运行时生成物"，除了按主机生成的 niri-hardware.kdl，配置是全静态的。
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

    # niri-hardware.kdl is generated per host (hosts/<host>/niri-hardware.kdl) and
    # is a hard `include`, so stub it for the standalone validation.
    printf '// stub for standalone validation\n' > "$work/niri-hardware.kdl"

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

    # ── Clavis 运行时片段必须是 optional ────────────────────────────────────
    # 片段由外壳自己写（第一次启动后才有）。写成硬 include 的话，登录前的那次
    # niri 启动会因缺文件直接失败 —— 也就是"第一次开机黑屏"。
    if ! grep -q 'include optional=true "clavis/effects.kdl"' "$work/config.kdl"; then
      echo 'config.kdl must include "clavis/effects.kdl" with optional=true' >&2
      exit 1
    fi

    # ── 外壳依赖的环境变量必须非空 ──────────────────────────────────────────
    # environment {} 只影响 niri 拉起的进程；systemd user unit 里的同名变量
    # 由 modules/home/desktop/clavis 负责（unitEnvironment）。两处缺一个，
    # 外壳就退回空图标（紫黑棋盘格）或不画背景。
    for name in QS_ICON_THEME QT_QPA_PLATFORMTHEME_QT6 ELECTRON_OZONE_PLATFORM_HINT XMODIFIERS; do
      value=$(sed -nE "s/^[[:space:]]*''${name}[[:space:]]+\"([^\"]+)\".*/\1/p" "$work"/*.kdl | tail -n1)
      if [ -z "$value" ]; then
        echo "niri config does not define $name with a non-empty value" >&2
        exit 1
      fi
      echo "niri environment: $name=$value"
    done

    touch $out
  ''
