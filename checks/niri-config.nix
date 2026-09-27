# niri KDL config validation (no VM, no network: just `niri validate`).
#
# Why: home/niri/*.kdl is a set of `include`s parsed only at niri startup, so a
# typo (e.g. `spawn-sh` outside `binds {}`) survives `home-manager switch` and
# only shows up as a black screen / ignored keybinding after the next login.
# `niri validate` catches it in CI instead.
#
# iNiR 不再往 ~/.config/niri/ 里写任何片段（配色/壁纸/光标都是它自己的层或
# 模板输出），所以这里不需要 stub 什么"运行时生成物"：除了按主机生成的
# niri-hardware.kdl，配置是全静态的。
{ pkgs, ... }:
pkgs.runCommand "niri-config-validate"
{
  nativeBuildInputs = [ pkgs.niri ];
} ''
  set -euo pipefail

  src=${../home/niri}
  work=$TMPDIR/niri
  mkdir -p "$work"
  cp "$src"/*.kdl "$work/"

  # niri-hardware.kdl is generated per host (hosts/<host>/niri-hardware.kdl) and
  # is a hard `include`, so stub it for the standalone validation.
  printf '// stub for standalone validation\n' > "$work/niri-hardware.kdl"

  niri validate -c "$work/config.kdl"

  # 桌面壳 IPC 一律走 `inir`（上游 CLI：inir <target> <function>）。留个断言，
  # 免得以后又有人把 key ipc / clavis 抄回来 —— 那些命令已经不存在了。
  if grep -qE 'key ipc|clavis' "$work"/*.kdl; then
    echo "home/niri/*.kdl still references the removed Clavis shell (key ipc)" >&2
    grep -nE 'key ipc|clavis' "$work"/*.kdl >&2
    exit 1
  fi

  touch $out
''
