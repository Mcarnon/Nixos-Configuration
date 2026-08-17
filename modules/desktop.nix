# Graphical desktop: niri compositor + Noctalia shell + greetd + PipeWire.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    inputs.noctalia.nixosModules.default
  ];

  # Graphics: OpenGL + VA-API. Adjust extraPackages for AMD/NVIDIA if needed.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  # Audio: PipeWire with PulseAudio / ALSA compatibility.
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # Wayland compositor.
  programs.niri.enable = true;

  # Desktop shell (bar / launcher / notifications / ...).
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # Login manager; after login starts niri.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.niri}/bin/niri-session";
      };
    };
  };
}
