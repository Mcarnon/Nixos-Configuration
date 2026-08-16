{ lib, ... }:
{
  # Require the user's password for `sudo`.
  security.sudo.wheelNeedsPassword = true;

  # Uncomment for a stricter default (can interfere with some software):
  # security.rtkit.enable = true;
}
