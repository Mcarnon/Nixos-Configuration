# AI assistants / LLM CLIs for terminal use.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    # Terminal coding agent; also the default backend for opencode-based services.
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
}
