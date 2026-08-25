# flake-parts module: host registry (scale: add a host = one line;
# performance: flake-parts memoizes perSystem + flake outputs separately).
{ inputs, ... }:
{
  flake.nixosConfigurations =
    let
      lib = import ../lib { };
    in
    {
      # Single-host today; adding a second host is:
      #   desktop = lib.mkHost inputs { system = "x86_64-linux"; hostname = "desktop"; hostPath = ../hosts/desktop; };
      laptop = lib.mkHost inputs {
        system = "x86_64-linux";
        hostname = "laptop";
        hostPath = ../hosts/laptop;
      };
    };
}
