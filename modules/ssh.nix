# SSH: 连接另一台电脑远程同步/部署配置
{ config, pkgs, lib, ... }:
{
  programs.ssh = {
    enable = true;
    startAgent = true;

    matchBlocks = {
      # 远端电脑别名。运行 `ssh nixos-remote` 即可连接。
      # 配套的同步脚本见 scripts/sync.sh
      "nixos-remote" = {
        hostname = "192.168.1.100"; # TODO: 改成远端 IP 或域名
        user = "alice";             # TODO: 改成远端用户名
        # port = 22;
        # identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  # 可选: 让本机也开启 sshd, 以便另一台电脑反向同步本机。
  # services.openssh = {
  #   enable = true;
  #   settings.PasswordAuthentication = false;
  # };
}
