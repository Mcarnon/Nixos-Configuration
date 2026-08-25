# Role: nixos base — minimal host (no GUI)
# 组合 modules/nixos/core + network + security
{
  imports = [
    ../../modules/nixos/core
    ../../modules/nixos/network
    ../../modules/nixos/security
    ../../modules/nixos/i18n
  ];
}
