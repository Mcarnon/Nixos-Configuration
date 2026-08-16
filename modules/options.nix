# Central options for per-machine settings.
#
# Each host overrides these under the `my` namespace in its `default.nix`,
# and shared modules read them via `config.my.*`.
{ lib, ... }:
{
  options.my = {
    role = lib.mkOption {
      type = lib.types.enum [
        "desktop"
        "laptop"
        "vm"
      ];
      default = "desktop";
      description = "Role of this machine.";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "Hostname of this machine.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = "mccarnon";
      description = "Primary user account name.";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "McCarnon";
      description = "Full name of the primary user.";
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Asia/Shanghai";
      description = "System timezone.";
    };
  };
}
