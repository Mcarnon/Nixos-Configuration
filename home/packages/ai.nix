# AI assistants / LLM CLIs for terminal use.
{ config, pkgs, ... }:
let
  miyu = pkgs.callPackage ../../pkgs/miyu { };
in
{
  home.packages = with pkgs; [
    miyu
    # Terminal coding agent; also the default backend Miyu talks to.
    opencode

    # Zero-config chat CLI (multi-model, scriptable: `echo x | aichat`).
    aichat

    # Keyless terminal GPT via free endpoints; great for quick questions.
    tgpt
  ];

  # NOTE: claude-code (Anthropic's agent) is intentionally omitted here because
  # it requires a POSIX $SHELL and breaks under fish. To enable it, add
  # `claude-code` above and set:
  #   environment.sessionVariables.SHELL = "/run/current-system/sw/bin/bash";
  # (fish stays your interactive shell; claude-code just spawns bash for itself.)

  # ── Miyu model / opencode / prompt — how to configure after rebuild ──
  # Miyu stores config in SQLite under ~/.miyu (not a plain text file), so
  # the intended workflow is imperative via its TUI. After `nixos-rebuild` /
  # `home-manager switch` and a new shell:
  #
  #   1. (auto) home.activation runs `miyu init` if ~/.miyu is missing.
  #      You can also run `miyu init` or `miyu daemon start` manually.
  #   2. Verify paths: `miyu paths`  (shows config/data/cache locations)
  #   3. Open TUI:     `miyu config`
  #      - 供应商和模型: pick provider/model. Default is opencode public API.
  #        To use your own opencode / OpenAI-compatible endpoint, add a
  #        provider there and fill base URL + API key. Claude Code provider
  #        (v0.4.4+) uses your local `claude` CLI subscription, no API key.
  #      - 自定义提示词: create a new persona; default prompt is read-only.
  #        Also set 用户身份 for a more immersive chat.
  #   4. Alternative: `miyu models` to list/switch models without TUI.
  #   5. Migration: `miyu export` / `miyu import` to move ~/.miyu between machines
  #      (see `miyu export --dry-run` and README).
  #
  # The fish hook (home/miyu.fish → xdg.configFile fish/conf.d/zz-miyu.fish)
  # is declarative; no need to run `miyu fish-init` (that would conflict with
  # Home Manager which owns ~/.config/fish). To remove it: `miyu remove-shell-hook`
  # only affects imperative installs; for HM, delete the xdg.configFile line.
}
