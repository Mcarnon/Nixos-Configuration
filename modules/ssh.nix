# SSH 远程接入：让任何机器(macOS/Windows/Linux/手机)连进这台 NixOS。
#
#   在任意客户端执行:  ssh mccarnon@<本机IP>
#   登录密码:          首次激活用 initialPassword(host 配置里的 "nixos")
#   最优做法:          换成密钥后关闭密码登录(见下方注释)。
#
# 查本机 IP:  `ip a`  或  `ip route get 1.1.1.1 | awk '{print $7}'`
{ config, pkgs, lib, ... }:
{
  # 服务端：监听 22，防火墙已在 network.nix 放行。
  services.openssh = {
    enable = true;

    settings = {
      # 先允许密码登录(配合 initialPassword)，配好密钥后再改为 false。
      PasswordAuthentication = true;
      PermitRootLogin = "no"; # 禁止 root 直连，走普通用户 + sudo
    };

    # 需要公钥时，把密钥加进 host 配置的 users.users.<name>.openssh.authorizedKeys.keys
    # 然后这里 PasswordAuthentication 改 false。
    # 生成密钥(在本机):  ssh-keygen -t ed25519 -C "laptop"
    # 客户端私钥放 ~/.ssh/ 或用 ssh-copy-id 之类拷贝。
  };

  # 客户端侧(仅当你要从【这台】NixOS ssh 去别的机器时才需要)。
  # 如果你只是让别人连进这台机器，下面这段可以忽略或删除。
  programs.ssh = {
    extraConfig = ''
      Host nixos-remote
        HostName 192.168.2.68  # TODO: 想连的那台机器 IP
        User mccarnon
        # IdentityFile ~/.ssh/id_ed25519
    '';
  };
}
