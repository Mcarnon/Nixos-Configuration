# CI checks (security + performance regressions surface as `nix flake check`).
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      checks = { };
    };
}
