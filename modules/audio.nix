{ config, pkgs, lib, ... }:

let
  mySofFirmware = pkgs.runCommand "my-sof-firmware"
    { nativeBuildInputs = [ pkgs.zstd ]; }
    ''
      mkdir -p $out/lib/firmware/intel/sof
      mkdir -p $out/lib/firmware/intel/sof-tplg

      cp -L ${pkgs.sof-firmware}/lib/firmware/intel/sof/sof-tgl.ri.zst $out/lib/firmware/intel/sof/
      cp -L ${pkgs.sof-firmware}/lib/firmware/intel/sof-tplg/sof-tgl-es8336.tplg.zst $out/lib/firmware/intel/sof-tplg/

      zstd -d $out/lib/firmware/intel/sof/sof-tgl.ri.zst -o $out/lib/firmware/intel/sof/sof-tgl.ri
      zstd -d $out/lib/firmware/intel/sof-tplg/sof-tgl-es8336.tplg.zst -o $out/lib/firmware/intel/sof-tplg/sof-tgl-es8336-dmic2ch.tplg

      rm $out/lib/firmware/intel/sof/sof-tgl.ri.zst
      rm $out/lib/firmware/intel/sof-tplg/sof-tgl-es8336.tplg.zst
    '';
in
{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.firmware = [ mySofFirmware ];

  boot.kernelParams = [
    "snd-intel-dspcfg.dsp_driver=3"
    "sof_pci_debug=1"
  ];

  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
    options snd_soc_sof_es8336 quirk=0x02
  '';

  boot.initrd.kernelModules = [
    "snd_soc_sof_es8336"
    "snd_sof_pci_intel_tgl"
  ];

  environment.systemPackages = with pkgs; [
    alsa-utils
    sof-tools
    zstd
  ];
}
