{ lib, ... }:
{
  # Require the user's password for `sudo`.
  security.sudo.wheelNeedsPassword = true;

  # Real-time priority for audio (required by PipeWire).
  security.rtkit.enable = true;
}
