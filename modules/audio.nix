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

  # ESS8336 codec (Intel 500-series / Tiger Lake) uses the SOF DSP path; if
  # `aplay -l` shows nothing and dmesg says the sof-tplg es8336 topology is
  # missing, the topology must be made available. Forcing legacy HDA is a
  # quick test, though this I2S codec often stays silent on it:
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=1  # legacy HDA (quick test, may not work)
  '';
}
