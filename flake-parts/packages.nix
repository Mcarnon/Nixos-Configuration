# perSystem packages & formatter (performance: perSystem eval is cached once per system).
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      formatter = pkgs.nixfmt-rfc-style;
    };
}
