# CI checks
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      miyuTest = pkgs.callPackage ../checks/miyu.nix { inherit inputs; };
    in
    {
      checks = {
        miyu-smoke = miyuTest;
      };
    };
}
