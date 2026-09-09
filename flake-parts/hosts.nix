# flake-parts module
{ inputs, ... }:
{
  flake.nixosConfigurations =
    let
      lib = import ../lib;
    in
    {
      laptop = lib.mkHost inputs {
        system = "x86_64-linux";
        hostname = "laptop";
        hostPath = ../hosts/laptop;
      };
      # planning for more hosts
    };
}
