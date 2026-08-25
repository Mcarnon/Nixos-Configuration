# Profile: desktop — shim to roles/nixos/desktop (保留兼容)
{ config, pkgs, lib, ... }:
{
  imports = [ ../roles/nixos/desktop.nix ];
}
