# 最小模块：无选项，直接生效
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ htop ];
}
