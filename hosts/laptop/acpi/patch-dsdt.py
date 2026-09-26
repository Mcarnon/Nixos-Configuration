#!/usr/bin/env python3
"""Hide the phantom Everest ES8336 codec in this machine's DSDT.

Huawei's DSDT declares the codec at \\_SB_.PC00.I2C2.ESSX, but ACPI I2C2 maps to
PCI 00:15.2, which this board does not expose (only I2C0 / 00:15.0 exists). The
codec can therefore never be instantiated, yet the kernel keeps finding it:
Intel SOF matches machine drivers by ACPI HID, so it picks the unusable
`sof-essx8336` machine driver, which then requests
`intel/sof-tplg/sof-tgl-es8336-dmic2ch.tplg` - a topology name that current
sof-bin releases no longer ship (only the `-ssp0/-ssp1/-ssp2` variants). The
probe fails with -ENOENT and no sound card is created at all.

Renaming the HID (and _CID) in place makes `acpi_dev_present("ESSX8336")` fail,
so SOF falls through to the HDA machine driver (`skl_hda_dsp_generic` with
`sof-hda-generic-2ch.tplg`), which drives the codecs that really are wired
(HDA #0 Conexant SN6140, HDA #2 Intel HDMI) plus the PCH digital mic array.

The rename is length-preserving: AML String constants are `0x0D <ASCII> 0x00`
with no length field, so no offset inside the table moves. Afterwards the OEM
revision is bumped and the table checksum recomputed, because the initrd
override is only applied when the table matches the platform one (same
signature / OEMID / OEM table ID) and carries a newer OEM revision.

Usage: patch-dsdt.py <DSDT.raw> <out.aml>
"""

import sys

SRC, DST = sys.argv[1], sys.argv[2]
OLD_HID, NEW_HID = b"ESSX8336", b"ESSX8337"

data = bytearray(open(SRC, "rb").read())

# --- sanity: header, size field and checksum of the dumped table -------------
assert data[0:4] == b"DSDT", f"{SRC}: not a DSDT (signature {data[0:4]!r})"
assert int.from_bytes(data[4:8], "little") == len(data), (
    f"{SRC}: length field {int.from_bytes(data[4:8], 'little')} != file size {len(data)}"
)
assert sum(data) % 256 == 0, f"{SRC}: ACPI checksum is invalid"

# --- the actual fix ----------------------------------------------------------
hits = data.count(OLD_HID)
assert hits == 2, f"{SRC}: expected 2 {OLD_HID.decode()} HIDs (_HID and _CID), found {hits}"
data = bytearray(bytes(data).replace(OLD_HID, NEW_HID))

# --- checklist: newer OEM revision so the override wins ----------------------
oem_revision = int.from_bytes(data[24:28], "little")
assert oem_revision < 0xFFFFFFFF, f"{SRC}: OEM revision {oem_revision} cannot be bumped"
data[24:28] = (oem_revision + 1).to_bytes(4, "little")

# --- checklist: checksum over the whole table --------------------------------
data[9] = 0
data[9] = (-sum(data)) % 256
assert sum(data) % 256 == 0

open(DST, "wb").write(bytes(data))
print(
    f"{SRC} -> {DST}: {hits} HIDs renamed, "
    f"OEM revision {oem_revision} -> {oem_revision + 1}, checksum fixed"
)
