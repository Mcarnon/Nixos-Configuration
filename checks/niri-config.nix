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
{
  pkgs,
  inputs,
  inirPackage,
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

    # 桌面壳 IPC 一律走 `inir`（上游 CLI：inir <target> <function>）。留个断言，
    # 免得以后又有人把 key ipc / clavis 抄回来 —— 那些命令已经不存在了。
    if grep -qE 'key ipc|clavis' "$work"/*.kdl; then
      echo "home/niri/*.kdl still references the removed Clavis shell (key ipc)" >&2
      grep -nE 'key ipc|clavis' "$work"/*.kdl >&2
      exit 1
    fi

    # ── iNiR launcher 的静默 exit 1 地雷 ────────────────────────────────────
    # iNiR 的 apply_niri_app_environment() 从【本配置】里 grep 一组变量名塞进
    # 环境，循环体是 `[[ -n "$value" ]] && export "''${name}=''${value}"`。列表里最后
    # 一个名字缺失（非空才算有值）时函数返回 1，而 launcher 脚本是
    # `set -euo pipefail` —— 整个进程直接死掉，**不打印任何东西**：症状是
    # inir.service 起来 ~0.2s 就 exit 1、journal 里零日志、桌面全黑只剩光标。
    # 这个断言从 iNiR 包里把列表解析出来（上游改了顺序/追加名字会自动跟随），
    # 只要求「末位」在 environment 块里有非空值。
    launcher=${inirPackage}/share/quickshell/inir/scripts/inir
    if [ ! -x "$launcher" ] && [ ! -f "$launcher" ]; then
      echo "cannot find iNiR launcher at $launcher (upstream layout changed?)" >&2
      exit 1
    fi
    # 先把 `\` + 换行的续行拼成一行，否则列表会被行尾反斜杠截断。
    flat=$(sed ':a;N;$!ba;s/\\\n//g' "$launcher")
    names=$(printf '%s\n' "$flat" | grep -oE 'for name in [A-Z_]+( +[A-Z_]+)*' | head -n1 | cut -d' ' -f4- | tr -s ' ')
    if [ -z "$names" ]; then
      echo "could not parse iNiR's app-environment variable list from $launcher" >&2
      exit 1
    fi
    last=$(printf '%s\n' "$names" | awk '{print $NF}')
    value=$(sed -nE "s/^[[:space:]]*''${last}[[:space:]]+\"([^\"]+)\".*/\1/p" "$work"/*.kdl | tail -n1)
    if [ -z "$value" ]; then
      echo "niri config does not define $last with a non-empty value." >&2
      echo "iNiR greps this file for: $names" >&2
      echo "Missing the last entry makes its launcher exit 1 silently (black screen)." >&2
      exit 1
    fi
    echo "iNiR app-environment: $last=$value (last of: $names)"

    touch $out
  ''
