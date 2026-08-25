# Audio: PipeWire (Noctalia's volume OSD / app audio depend on it)
{ config, pkgs, lib, ... }:
{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # PulseAudio compatibility layer (needed by Firefox etc.)
    # jack.enable = true; # enable if you need JACK audio
  };
}
