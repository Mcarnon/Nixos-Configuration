{ config, pkgs, lib, ... }:

let
  mySofFirmware = pkgs.runCommand "my-sof-firmware"
    { nativeBuildInputs = [ pkgs.zstd ]; }
    ''
      mkdir -p $out/lib/firmware/intel/sof
      mkdir -p $out/lib/firmware/intel/sof-tplg

      # 复制固件（实际文件在 intel-signed 子目录）
      cp -L ${pkgs.sof-firmware}/lib/firmware/intel/sof/intel-signed/sof-tgl.ri.zst $out/lib/firmware/intel/sof/
      # 复制拓扑（在 sof-tplg 目录下）
      cp -L ${pkgs.sof-firmware}/lib/firmware/intel/sof-tplg/sof-tgl-es8336.tplg.zst $out/lib/firmware/intel/sof-tplg/

      # 解压固件
      zstd -d $out/lib/firmware/intel/sof/sof-tgl.ri.zst -o $out/lib/firmware/intel/sof/sof-tgl.ri

      # 解压拓扑并重命名为驱动期望的名称
      zstd -d $out/lib/firmware/intel/sof-tplg/sof-tgl-es8336.tplg.zst -o $out/lib/firmware/intel/sof-tplg/sof-tgl-es8336-dmic2ch.tplg

      # 删除压缩文件，避免干扰
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
