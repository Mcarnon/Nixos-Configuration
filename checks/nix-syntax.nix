# Parse-only syntax check for every tracked .nix file in the repo.
#
# Why: home-manager and NixOS modules are only evaluated when the host is built,
# so a brace/paren mistake introduced while editing one module does not surface
# until `nixos-rebuild`. `nix-instantiate --parse` catches it in CI.
#
# This deliberately does NOT evaluate: the point is a fast, dependency-free
# signal. `nix flake check` covers evaluation and the derivation builds.
{ pkgs, lib, ... }:
let
  nixFiles = pkgs.lib.cleanSourceWith {
    src = ../.;
    filter =
      path: type:
      let
        base = baseNameOf (toString path);
      in
      type == "regular" && lib.hasSuffix ".nix" base;
  };
in
pkgs.runCommand "nix-syntax-check"
  {
    nativeBuildInputs = [ pkgs.nix ];
  }
  ''
    set -euo pipefail

    src=${nixFiles}

    # nix-instantiate (even bare --parse) insists on creating $NIX_STATE_DIR/
    # profiles on every invocation, and in the sandbox the default /nix/var/nix is
    # read-only -- give it a private writable location so the sandbox can never
    # decide the parse "failed" just because it could not touch the host state.
    export NIX_STATE_DIR="$TMPDIR/nix-state"
    mkdir -p "$NIX_STATE_DIR"

    fail=0
    count=0
    # Plain newline-delimited: repo paths never contain newlines, and it keeps the
    # loop clear of the NUL-delimiter quoting dance (two adjacent single quotes are
    # a broken escape inside a Nix indented string, not an empty shell argument).
    while IFS= read -r file; do
      count=$((count + 1))
      if ! err=$(nix-instantiate --parse "$file" 2>&1 >/dev/null) || [ -n "$err" ]; then
        echo "syntax error in $file"
        echo "$err" | head -20
        fail=1
      fi
    done <<EOF
    $(find "$src" -name '*.nix' -type f | sort)
    EOF

    if [ "$count" -eq 0 ]; then
      echo "nix-syntax-check found no .nix files -- the source filter is broken" >&2
      exit 1
    fi

    if [ "$fail" -ne 0 ]; then
      exit 1
    fi

    echo "parsed $count nix files"
    touch $out
  ''
