# Android Device Tree for the Motorola Edge 40 (lyriq)

```
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
```

Unofficial port of **LineageOS 22.2 (Android 15)** and **PixelOS (Android 16)** for the Motorola Edge 40 (codename `lyriq`).

This port is a **personal hobby project**, done purely for fun, learning and research in the maintainer's own spare time. It is not a commercial effort and has no affiliation with any vendor or ROM team (see Disclaimer).

## Status

| Branch | ROM | Android | State |
|--------|-----|---------|-------|
| `lineage-22.2` | LineageOS 22.2 | 15 | All features verified working on the maintainer's device (final acceptance 2026-08-12); **no stability is claimed or guaranteed** — see Disclaimer |
| `sixteen-qpr2` | PixelOS | 16 | Verified working on device; requires the kernel patches listed below (to be published separately) |

**LineageOS 22.2 feature status (verified on device):**

- Boots, SELinux enforcing, signed with release-keys
- Display (144 Hz, punch-hole cutout, rounded corners, auto-brightness)
- Touch and edge gestures
- WiFi, mobile data (4G/5G SA), calls, VoLTE/VoNR
- Physical SIM and eSIM
- Camera (all three rear sensors) and video recording/playback
- In-display fingerprint (enroll, unlock, AOD unlock)
- TEE, KeyMint/Gatekeeper, FBE with wrappedkey
- NFC, GPS, sensors, vibrator
- Audio, Bluetooth
- AOD (doze) and Peek Display

**Known issues:**

- Lift-to-wake does not work.
- AOD runs through the generic doze path; the panel has no real AOD mode, so power draw is higher than on stock.
- Screen flickers at certain brightness levels. Workaround: lower the brightness or disable the adaptive refresh rate.

## Device specifications

| Component | Detail |
|-----------|--------|
| SoC | MediaTek Dimensity 8020 (MT6891; platform codename `mt6893`) |
| Kernel | 6.6.89, GKI (`android15-8`), built from Motorola open-source releases |
| Display | pOLED, up to 144 Hz, punch-hole cutout |
| Storage | UFS |
| Rear cameras | OV50E (main), OV50A/OV32B (ultrawide), HI1336 (macro) |
| Fingerprint | In-display optical (UDFPS) |
| Stock base | Android 15, build `V1TLS35.73-60-3-9` |

## Supported devices

- **Motorola Edge 40 XT2303-2 (lyriq)**, Global variant (`lyriq_g`).
- Other regional variants are untested. Flash only on a matching codename.

## How to build

```bash
# LineageOS 22.2 (Android 15) / PixelOS (Android 16)
breakfast lyriq userdebug
```

Proprietary blobs are extracted from the stock firmware with `extract-files.py`; never edit the generated vendor tree manually.

## Required patches

This device tree alone is **not** sufficient for a fully functional build. The following patches on top of the ROM sources are required and will be published separately:

- **Kernel patches** — required for PixelOS (Android 16). Without them the device will not function correctly on this branch.
- **`frameworks/base`** — UDFPS touch forwarding, panel HBM toggle, FOD illumination via the stock panel HAL, UDFPS illumination through capture, and UDFPS refresh-rate vote handling. All gated behind `ro.vendor.fod.framework_managed`; no-ops on other devices.
- **`frameworks/opt/telephony`** — injectable RIL factory compatibility and Moto ext-telephony hooks (required for eSIM).
- **`build/make`** — allow the vendor to opt out of the deprecated CAS 1.2 HIDL service in `base_vendor.mk`. Not required in Android 16.

## Contributing

Community involvement is welcome and encouraged. Feel free to fork this tree, modify it, and build upon it — bug reports, testing, fixes and improvements are all appreciated. Please open an issue or a pull request on this repository if you want to contribute changes back. I do not have much free time so do not expect immediate bug fixes or features.

If you reuse significant parts of this tree in your own work, keeping the credits below intact is appreciated.

## Credits

- **Maintainer:** [@102464](https://github.com/102464)
- **Base device tree:** built on top of the community-maintained skeleton [android_device_motorola_lyriq by @Addster09](https://github.com/Addster09/android_device_motorola_lyriq) (branch `lineage-22.2`). Its skeleton files (`Android.bp`, `AndroidProducts.mk`, `BoardConfig.mk`, `device.mk`, `proprietary-files.txt`, etc.) originate from that tree, which in turn aggregates work by many contributors, including [@claxten10](https://github.com/claxten10), [@Alvyrion](https://github.com/Alvyrion), [@rio004](https://github.com/rio004), [@sarthakroy2002](https://github.com/sarthakroy2002), [@Woomymy](https://github.com/Woomymy), [@LuK1337](https://github.com/LuK1337), [@bengris32](https://github.com/bengris32), [@SGCMarkus](https://github.com/SGCMarkus), [@dianlujitao](https://github.com/dianlujitao), [@Erfan Abdi](https://github.com/erfanoabdi), and others.
- [The LineageOS Project](https://github.com/LineageOS) and [PixelOS-AOSP](https://github.com/PixelOS-AOSP) for the ROM sources.
- MotorolaMobility for the open-source kernel and device module releases.

## Disclaimer

- This is an **unofficial** port. It is not affiliated with, endorsed by, or supported by MotorolaMobility, the LineageOS Project, or PixelOS.
- **No stability, fitness, or reliability is claimed or guaranteed.** Features were verified working on the maintainer's own unit; your mileage may vary.
- Flashing this software may void your warranty and can brick your device. You do everything **at your own risk**; the authors take no responsibility for any damage, data loss, or broken hardware. This device has NO traditional Preloader/BROM mode for blankflashing. You need to reprogram UFS if the device cannot enter fastboot. You have been WARNED.
- Proprietary vendor blobs remain the property of their respective owners and are redistributed solely to enable interoperability with this device.
- Always back up your data before flashing.

## Donations

This port was built entirely in the maintainer's personal spare time, out of pocket — besides countless hours, it also consumed part of a paid coding-plan subscription.

If this work is useful to you and you would like to help offset these costs (the coding plan) or just want to give the maintainer a coffee, donations are sincerely appreciated. **Ko-fi:** [ko-fi.com/102464](https://ko-fi.com/102464).

You can also reach out via [GitHub Sponsors](https://github.com/sponsors/102464) or by opening an issue on this repository. Bug reports, testing and code contributions are just as welcome.

## License

This device tree is licensed under the Apache License 2.0. See the SPDX headers in individual files for details.
