# ACPI table override — hide the phantom Everest ES8336 codec.
#
# Why: this board's DSDT declares an ES8336 codec at \_SB_.PC00.I2C2.ESSX, but
# ACPI I2C2 is PCI 00:15.2, which Quanta never wired up here (only I2C0 /
# 00:15.0 exists). The codec is therefore unreachable, yet Intel SOF matches
# machine drivers by ACPI HID and picks the unusable `sof-essx8336` driver,
# which then requests `intel/sof-tplg/sof-tgl-es8336-dmic2ch.tplg` — a topology
# name current sof-bin releases no longer ship — and the probe dies with -ENOENT
# (no sound card at all).
#
# With the HID renamed (see ./acpi/patch-dsdt.py) the ES8336 match fails, so SOF
# falls through to the HDA machine driver (`skl_hda_dsp_generic` +
# `sof-hda-generic-2ch.tplg`), which drives the codecs that really are wired
# (HDA #0 Conexant SN6140, HDA #2 Intel HDMI) and the PCH digital mic array
# (NHLT: 2 DMICs) — i.e. internal speakers, headphones, headset mic, internal
# mic and HDMI all live under SOF.
#
# Regenerating DSDT.raw after a BIOS update (the override is only applied while
# its OEM revision is newer than the firmware's; bumping it is what the patch
# script does):
#   sudo cp /sys/firmware/acpi/tables/DSDT /tmp/DSDT.raw && cp /tmp/DSDT.raw ./acpi/DSDT.raw
#   python3 ./acpi/patch-dsdt.py ./acpi/DSDT.raw /tmp/out.aml   # sanity check
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Renames the ESSX8336 _HID/_CID in place (length-preserving), bumps the OEM
  # revision and recomputes the table checksum. The script asserts the dumped
  # table looks the way we expect, so a wrong/updated DSDT fails the build
  # instead of silently producing a bad table.
  patchedDsdt = pkgs.runCommandLocal "dsdt-no-essx8336" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 ${./acpi/patch-dsdt.py} ${./acpi/DSDT.raw} "$out"
  '';

  # The kernel only looks for overrides in an *uncompressed* cpio archive that
  # sits at kernel/firmware/acpi/ and comes first in the initrd
  # (Documentation/admin-guide/acpi/initrd_table_override.rst). `boot.initrd.prepend`
  # places it exactly there, uncompressed, ahead of the compressed main image.
  acpiOverrideCpio = pkgs.runCommandLocal "acpi-override.cpio" { nativeBuildInputs = [ pkgs.cpio ]; } ''
    mkdir -p kernel/firmware/acpi
    cp ${patchedDsdt} kernel/firmware/acpi/dsdt.aml
    find kernel -print0 | sort -z | cpio --quiet -o -H newc -R +0:+0 --reproducible --null > "$out"
  '';
in
{
  # `boot.initrd.prepend` takes store path strings (types.listOf types.str).
  boot.initrd.prepend = [ "${acpiOverrideCpio}" ];
}
