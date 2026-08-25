# User shell: fish + starship + direnv, plus proxy on/off helpers.
{ config, pkgs, lib, ... }:
let
  miyuPkg = pkgs.callPackage ../pkgs/miyu { };
in
{
  programs.starship.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';

    # Terminal proxy toggles (clash-verge-rev's default mixed port is 7897).
    functions = {
      proxy_on = {
        description = "启用终端代理（默认端口 7897，可传参覆盖）";
        body = ''
          set -l port 7897
          if set -q argv[1]
              set port $argv[1]
          end
          set -gx http_proxy "http://127.0.0.1:$port"
          set -gx https_proxy "http://127.0.0.1:$port"
          set -gx all_proxy "socks5://127.0.0.1:$port"
          echo "proxy on -> 127.0.0.1:$port"
        '';
      };
      proxy_off = {
        description = "关闭终端代理";
        body = ''
          set -e http_proxy
          set -e https_proxy
          set -e all_proxy
          echo "proxy off"
        '';
      };
    };
  };

  # Per-project dev shells: .envrc + `use flake` loads automatically.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true; # ls/ll aliases
    git = true;
    icons = "auto";
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true; # `z` smart cd
  };

  # Miyu fish hook — declarative equivalent of `miyu fish-init`.
  # Source is ./miyu.fish (verbatim upstream output). Installed as zz-miyu.fish
  # so it loads AFTER starship (conf.d is alphabetical; starship.fish < zz-miyu.fish),
  # ensuring the wrapper sees starship's fish_prompt.
  xdg.configFile."fish/conf.d/zz-miyu.fish".source = ./miyu.fish;

  # Auto-init Miyu state on first HM switch so `miyu config` / daemon work
  # without a manual `miyu init`. Idempotent — only runs if ~/.miyu is missing.
  home.activation.miyuInit = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/.miyu" ]; then
      echo "Miyu: initializing ~/.miyu (first run)..."
      $DRY_RUN_CMD ${miyuPkg}/bin/miyu init 2>/dev/null || true
    fi
  '';

  # Optional daemon auto-start (Miyu normally starts daemon on-demand from the
  # shell hook / REPL, so this is NOT required. Uncomment if you want it always
  # resident — e.g. for WebUI / QQ bridge without opening a terminal first).
  # systemd.user.services.miyu-daemon = {
  #   Unit = {
  #     Description = "Miyu daemon (AI assistant)";
  #     After = [ "graphical-session.target" ];
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #   Service = {
  #     ExecStart = "${miyuPkg}/bin/miyu daemon start";
  #     Restart = "on-failure";
  #   };
  #   Install.WantedBy = [ "graphical-session.target" ];
  # };
}
