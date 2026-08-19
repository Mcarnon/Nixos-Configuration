# 音频: PipeWire (Noctalia 音量 OSD / 应用音频都依赖它)
{ config, pkgs, lib, ... }:
{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # PulseAudio 兼容层 (Firefox 等应用需要)
    # jack.enable = true; # 如需 JACK 音频
  };
}
