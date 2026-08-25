# Home profile: desktop — shim to roles/home/desktop (保留兼容)
{ config, pkgs, lib, ... }:
{
  imports = [ ../../roles/home/desktop.nix ];
}
