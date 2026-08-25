# lib — shared helpers (scale: cross-host reuse; dedup: single source of truth).
# All helpers are pure and take `inputs` explicitly to stay flake-part-friendly.
{
  # mkHost: canonical nixosSystem wrapper
  # - Applies the repo overlay (pkgs/default.nix) so `pkgs.miyu` is globally available
  # - Wires agenix + home-manager exactly once (security: single decryption/activation path)
  # - Performance: avoids per-host boilerplate eval duplication
  mkHost =
    inputs: {
      system,
      hostname,
      hostPath,
      extraModules ? [ ],
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        inherit hostPath;
      };
      modules = [
        # Global overlay + nixpkgs hardening (single audit surface)
        { nixpkgs.overlays = [ (import ../pkgs/default.nix) ]; }
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        hostPath
      ]
      ++ extraModules;
    };

  # hardware helpers (HAL) — map a declarative attrset to concrete modules
  # Example: lib.hardware.intel -> imports intel microcode + gpu iris-xe
  hardware = {
    intel = ../modules/hardware/intel.nix;
  };
}
