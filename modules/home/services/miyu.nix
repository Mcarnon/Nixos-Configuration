# Miyu AI assistant — domain module (performance: prebuilt binary via overlay `pkgs.miyu`;
# security: single `pkgs.miyu` audit surface, no ad-hoc callPackage).
#
# Model / opencode / prompt — how to configure after rebuild:
# Miyu stores config in SQLite under ~/.miyu (not a plain text file), so the
# intended workflow is imperative via its TUI. After `nixos-rebuild` / `home-manager switch`:
#   1. (auto) home.activation runs `miyu init` if ~/.miyu is missing (or run `miyu init` / `miyu daemon start` manually).
#   2. Verify: `miyu paths` (shows config/data/cache locations)
#   3. Open TUI: `miyu config` → 供应商和模型 (default is opencode public API; add your own OpenAI-compatible endpoint or enable Claude Code provider which reuses local `claude` subscription) → 自定义提示词 (new persona; default read-only) + 用户身份.
#   4. Also: `miyu models` to switch without TUI, `miyu daemon logs request` to inspect real LLM requests.
#   5. Migration: `miyu export` / `miyu import` (see `miyu export --dry-run` and README).
# Fish hook is declarative at xdg.configFile `fish/conf.d/zz-miyu.fish` (../files/miyu.fish, loads after starship); never run `miyu fish-init` under HM.
{ config, pkgs, lib, ... }:
{
  # Package comes from the repo overlay (pkgs/default.nix); no `callPackage` at call sites.
  home.packages = [ pkgs.miyu ];

  # Declarative equivalent of `miyu fish-init` — lives in conf.d/zz-* so it loads after starship.
  xdg.configFile."fish/conf.d/zz-miyu.fish".source = ../../../home/files/miyu.fish;

  # First-run init: idempotent, only if ~/.miyu missing. Runs at HM activation (not every shell).
  home.activation.miyuInit = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/.miyu" ]; then
      echo "Miyu: initializing ~/.miyu (first run)..."
      $DRY_RUN_CMD ${pkgs.miyu}/bin/miyu init 2>/dev/null || true
    fi
  '';

  # Optional: always-resident daemon (off by default — Miyu starts on demand from shell/REPL).
  # systemd.user.services.miyu-daemon = {
  #   Unit = { Description = "Miyu daemon"; After = [ "graphical-session.target" ]; PartOf = [ "graphical-session.target" ]; };
  #   Service = { ExecStart = "${pkgs.miyu}/bin/miyu daemon start"; Restart = "on-failure"; };
  #   Install.WantedBy = [ "graphical-session.target" ];
  # };
}
