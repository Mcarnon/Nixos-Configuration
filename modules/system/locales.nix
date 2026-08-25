# System locales — thin re-export; real locale framework lives in ../../locales/.
# Keeping locales/ at top-level preserves per-region profiles (zh-cn, ja-jp, ...).
{ config, pkgs, lib, ... }:
{
  imports = [ ../../locales ];
}
