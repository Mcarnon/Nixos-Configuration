# Security: sops placeholder (agenix is the active backend; keep sops as future option).
{ config, pkgs, lib, ... }:
{
  # Example interop: if you migrate to sops-nix, enable here and keep agenix as fallback.
  # sops.defaultSopsFile = ../secrets/secrets.yaml;
}
