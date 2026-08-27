# perSystem packages & formatter (performance: perSystem eval is cached once per system).
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      packages.miyu = pkgs.callPackage ../pkgs/miyu { };
      formatter = pkgs.nixfmt;
    };
}
