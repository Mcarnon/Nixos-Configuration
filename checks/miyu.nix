# NixOS VM test: Miyu package + fish hook (security: no network, smoke only).
# Performance: VM boots once, runs two quick checks.
{ pkgs, ... }:
pkgs.testers.nixosTest {
  name = "miyu-smoke";
  nodes.machine =
    { config, pkgs, ... }:
    {
      # Reuse the repo's miyu overlay (pkgs.miyu already via overlay; inject here for the test VM)
      nixpkgs.overlays = [ (import ../pkgs/default.nix) ];
      environment.systemPackages = [ pkgs.miyu ];
      # Fish + starship present so the hook's `fish_prompt` wrap is realistic
      programs.fish.enable = true;
      # Minimal HM-less hook install for the test
      environment.etc."fish/conf.d/zz-miyu.fish".source = ../home/files/miyu.fish;
    };
  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("test -x /run/current-system/sw/bin/miyu")
    machine.succeed("miyu --help | grep -q \"shell-intercept\"")
    machine.succeed("test -f /etc/fish/conf.d/zz-miyu.fish")
    # Smoke: hook loads without error in fish
    machine.succeed("fish -c 'source /etc/fish/conf.d/zz-miyu.fish; functions -q __miyu_wrap_fish_prompt && echo ok' | grep -q ok")
  '';
}
