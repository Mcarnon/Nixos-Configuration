# Audio: PipeWire (Clavis' volume OSD / app audio depend on it)
{
  config,
  pkgs,
  lib,
  ...
}:
{
  security.rtkit.enable = true;

  # SOF firmware for modern Intel laptops (no sound without this)
  hardware.firmware = with pkgs; [ sof-firmware ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # PulseAudio compatibility layer (needed by Firefox etc.)
    wireplumber.enable = true; # session manager — required or no sinks
    # jack.enable = true; # enable if you need JACK audio
  };

  # Ensure PulseAudio daemon is disabled (PipeWire replaces it)
  services.pulseaudio.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    pulseaudio # pactl/pavucontrol for debugging
    alsa-ucm-conf
    alsa-utils # alsamixer/aplay for debugging
  ];
}
