# Profile: base — shim to roles/nixos/base (保留兼容)
{ config, pkgs, lib, ... }:
{
  imports = [ ../roles/nixos/base.nix ];
}
