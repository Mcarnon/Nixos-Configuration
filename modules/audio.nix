{ config, pkgs, lib, ... }:

let
  # 自定义固件包：解压 .zst 并重命名拓扑文件
  mySofFirmware = pkgs.runCommand "my-sof-firmware"
    { nativeBuildInputs = [ pkgs.zstd ]; }
    ''
      mkdir -p $out/lib/firmware/intel/sof
      mkdir -p $out/lib/firmware/intel/sof-tplg

      # 复制源文件（从 sof-firmware 包中）
      cp ${pkgs.sof-firmware}/lib/firmware/intel/sof/sof-tgl.ri.zst $out/lib/firmware/intel/sof/
      cp ${pkgs.sof-firmware}/lib/firmware/intel/sof-tplg/sof-tgl-es8336.tplg.zst $out/lib/firmware/intel/sof-tplg/

      # 解压固件（输出不加 .zst）
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

  # 使用自定义固件（优先级高于系统默认）
  hardware.firmware = [ mySofFirmware ];

  # 内核参数
  boot.kernelParams = [
    "snd-intel-dspcfg.dsp_driver=3"
    "sof_pci_debug=1"
  ];

  # 模块参数（针对 ES8336）
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
    options snd_soc_sof_es8336 quirk=0x02
  '';

  # 预加载音频模块（确保顺序）
  boot.initrd.kernelModules = [
    "snd_soc_sof_es8336"
    "snd_sof_pci_intel_tgl"
  ];

  environment.systemPackages = with pkgs; [
    alsa-utils
    sof-tools
    zstd  # 便于调试
  ];
}
