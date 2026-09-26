# Kernel — low-level performance / security (BBR, sysctl are in security/hardening.nix).
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Keep kernel-related toggles here when they are system-wide.
  # Host-specific kernelModules (e.g. kvm-intel) stay in hosts/*/hardware-configuration.nix for HAL reuse.
}
