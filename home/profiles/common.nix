# Home profile: common — shim to roles/home/common (保留兼容)
{ config, pkgs, lib, ... }:
{
  imports = [ ../../roles/home/common.nix ];
}
