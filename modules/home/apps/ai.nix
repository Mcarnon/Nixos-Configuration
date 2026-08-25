# AI assistants / LLM CLIs for terminal use (Miyu package lives in home/modules/miyu.nix via `pkgs.miyu`).
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
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
  # Miyu lives in home/modules/miyu.nix (pkgs.miyu) — see that file for model/opencode/prompt setup.
}
