# NixOS VM test: Miyu package + fish hook (security: no network, smoke only).
# Performance: VM boots once, runs two quick checks.
{ pkgs, inputs, ... }:
pkgs.testers.nixosTest {
  name = "miyu-smoke";
  nodes.machine =
    { config, pkgs, ... }:
    {
      # Reuse the repo's miyu overlay (pkgs.miyu already via overlay; inject here for the test VM)
      nixpkgs.overlays = [ (import ../pkgs/default.nix inputs) ];
      environment.systemPackages = [ pkgs.miyu ];
      # Fish + starship present so the hook's `fish_prompt` wrap is realistic
      programs.fish.enable = true;
      # Minimal HM-less hook install for the test
      environment.etc."fish/conf.d/zz-miyu.fish".source = ../home/files/miyu.fish;
    };
  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("test -x /run/current-system/sw/bin/miyu")
    # shell-intercept / shell-classify are hide=true in src/cli/args.rs:28, never in --help
    machine.succeed("miyu --shell-classify --shell fish 'echo hi'")
    machine.succeed("test -f /etc/fish/conf.d/zz-miyu.fish")
    # Smoke: hook loads without error in fish
    machine.succeed("fish -c 'source /etc/fish/conf.d/zz-miyu.fish; functions -q __miyu_wrap_fish_prompt && echo ok' | grep -q ok")
  '';
}
