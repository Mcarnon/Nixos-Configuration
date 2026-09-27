# Nix 语法冒烟检查：把仓库里所有 .nix 过一遍 parser。
#
# 为什么需要：模块只有在被 evalModules 真正 import 时才会被解析，而
# Home Manager 的模块要等 `system.build.toplevel`（assertions）被强制求值
# 才走到那儿。于是一个手滑的 `let` 位置错误、括号不配对、`${` 拼错，
# 都会伪装成「nixosConfigurations 求值失败」+ 一大段和文件名无关的栈，
# 排查成本极高。这里用 `nix-instantiate --parse`（只 parse，不 eval），
# 便宜、无网络、秒级返回，报错直接带文件名和行列号。
#
# 顺带守一个低级但致命的坑：imports 里写裸目录（`./foo`）时，求值器要靠
# 「目录 -> foo/default.nix」的回退；一旦那个 default.nix 没被带进 flake
# 源码（漏提交、.gitignore、稀疏检出等），报错就变成
#   module .../modules/.../foo (...) does not look like a module.
# 和真正的原因隔了十万八千里。凡是引目录的，必须真的有 default.nix。
{ pkgs, ... }:
pkgs.runCommand "nix-syntax-validate" { nativeBuildInputs = [ pkgs.nix ]; } ''
  set -euo pipefail

  # sandbox 里 HOME/XDG 指向 /nix/var/nix/...，对构建用户不可写，
  # nix-instantiate 还没开始 parse 就先吐
  #   error: creating directory "/nix/var/nix/profiles": Permission denied
  # 退出码非零 —— 会被本检查误报成全仓库 PARSE FAIL。把所有状态目录指到
  # 可写的临时目录，让退出码只反映 parse 结果。
  work=$(mktemp -d)
  export HOME="$work"
  export XDG_CACHE_HOME="$work/cache"
  export XDG_STATE_HOME="$work/state"
  export XDG_CONFIG_HOME="$work/config"
  export XDG_DATA_HOME="$work/data"
  export NIX_STATE_DIR="$work/nix-state"
  export NIX_CONF_DIR="$work/nix-conf"
  export NIX_LOG_DIR="$work/nix-log"
  mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_CONFIG_HOME" \
    "$XDG_DATA_HOME" "$NIX_STATE_DIR" "$NIX_CONF_DIR" "$NIX_LOG_DIR"
  export NIX_PATH=

  repo=${../.}

  echo "== 1/2 parsing every .nix under the repo =="
  fail=0
  while IFS= read -r f; do
    # 注意别把局部变量叫 out：那会覆盖 runCommand 注入的 $out（输出路径），
    # 最后一步 touch "$out" 就会去 touch 一个空文件名。
    if ! perr=$(nix-instantiate --parse "$f" 2>&1 >/dev/null); then
      echo "PARSE FAIL: ''${f#$repo/}" >&2
      echo "$perr" >&2
      fail=1
    fi
  done < <(find "$repo" -name '*.nix' -not -path '*/.git/*' | sort)
  [ "$fail" -eq 0 ] || exit 1

  echo "== 2/2 every directory referenced in an imports list has a default.nix =="
  # 两种写法都要抓：多行列表里的独立条目，以及 imports = [ ./x ] 这种单行。
  # 只匹配「整行就是一个 ./x」或「imports = [ ./x ]」，避免误伤 source = ../x 之类。
  pattern_a='^[[:space:]]+(\.\.?/)[A-Za-z0-9_.-]+[[:space:]]*$'
  pattern_b='imports[[:space:]]*=[[:space:]]*\[[[:space:]]*(\.\.?/)[A-Za-z0-9_.-]+[[:space:]]*\]'

  bad=0
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    file=''${hit%%:*}
    dir=$(printf '%s\n' "$hit" | grep -oE '(\.\.?/)[A-Za-z0-9_.-]+' | head -n1)
    [ -n "$dir" ] || continue
    case "$dir" in
      *.nix) continue ;;
    esac
    abs=$(dirname "$file")/$dir
    if [ ! -e "$abs/default.nix" ]; then
      echo "MISSING default.nix: $dir  (referenced from ''${file#$repo/})" >&2
      bad=1
      continue
    fi
    # 关键：模块系统对 imports 里的 path 是裸 `import`（lib/modules.nix 的
    # loadModule），目录能不能落到 default.nix 完全取决于求值器。把这一步
    # 单独拎出来跑，就不用等整包求值失败才看到 "does not look like a module"。
    kind=$(nix-instantiate --eval -E "builtins.typeOf (import $abs)" 2>/dev/null || echo error)
    if [ "$kind" != lambda ] && [ "$kind" != set ]; then
      echo "import $dir yields '$kind', expected lambda|set  (referenced from ''${file#$repo/})" >&2
      bad=1
    fi
  done < <(
    {
      # --exclude 本文件：上面的 pattern 变量和注释里写着 ./x 这种样例，
      # 自己 grep 自己必然误报。
      grep -rnE "$pattern_a" --include='*.nix' --exclude='nix-syntax.nix' "$repo" || true
      grep -rnE "$pattern_b" --include='*.nix' --exclude='nix-syntax.nix' "$repo" || true
    } | sort -u
  )
  [ "$bad" -eq 0 ] || exit 1

  touch $out
  echo "nix syntax OK"
''
