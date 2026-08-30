# fish shell: SHORiN-derived prompt helpers (y/cat/ls/lt/la/sl) + proxy toggles
# tools (starship/direnv/fzf/eza/zoxide) live in ./tools.nix
#
# Ported from shorin-arch-setup `minimal-niri-dotfiles/.config/fish`:
#   - y        yazi cd-back wrapper
#   - cat/ls/lt/la  bat/eza aliases
#   - sl       steam locomotive through lolcat
#   - fa       fastfetch alias
#   - f/fwatch random anime-girl fastfetch mascot (files under ../../home/files)
# Arch-specific bits (grub abbr, sysup, LM Studio PATH, raw wallpaper script)
# are intentionally dropped — they don't exist on NixOS.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    sl # steam locomotive (the joke `sl` function pipes it through lolcat)
    lolcat # rainbow output for sl
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';

    shellAbbrs = {
      fa = "fastfetch";
    };

    functions = {
      # ---- proxy toggles ----
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

      # ---- SHORiN functions ----
      y = {
        description = "启动 yazi 并在退出时 cd 到其所在目录";
        body = ''
          set tmp (mktemp -t "yazi-cwd.XXXXXX")
          yazi $argv --cwd-file="$tmp"
          if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
              builtin cd -- "$cwd"
          end
          rm -f -- "$tmp"
        '';
      };
      cat = {
        description = "bat 代替 cat";
        body = ''
          command bat --theme="base16" -- $argv
        '';
      };
      ls = {
        description = "eza 代替 ls";
        body = ''
          command eza --icons=auto -- $argv
        '';
      };
      lt = {
        description = "eza 树状视图";
        body = ''
          command eza --icons=auto --tree -- $argv
        '';
      };
      la = {
        description = "eza 长列表";
        body = ''
          command eza -l --icons=auto -- $argv
        '';
      };
      sl = {
        description = "小火车（lolcat 上色）";
        body = ''
          command sl | lolcat
        '';
      };
    };
  };

  # SHORiN's fastfetch anime-girl functions (self-contained; f = 随机看板娘，
  # fwatch = 循环模式，适合挂副屏）。需要 fastfetch/jq/curl（fastfetch 在
  # apps/cli.nix，jq 在下面补上）。
  xdg.configFile."fish/functions/f.fish".source = ../../../home/files/f.fish;
  xdg.configFile."fish/functions/fwatch.fish".source = ../../../home/files/fwatch.fish;
}
