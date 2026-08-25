# fish shell: prompt helpers + proxy toggles
# tools (starship/direnv/fzf/eza/zoxide) live in ./tools.nix
{ config, pkgs, lib, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';

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
}
