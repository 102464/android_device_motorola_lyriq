#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'device/motorola/lyriq',
    'hardware/mediatek',
    'hardware/mediatek/libmtkperf_client',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        'libcodec2_aidl',
        'libcodec2_hidl@1.0',
        'libcodec2_hidl@1.1',
        'libcodec2_hidl@1.2',
        'vendor.mediatek.hardware.videotelephony-V1-ndk',
        # These exist in both vendor and system_ext partitions with identical
        # basenames; suffix the vendor variants to avoid duplicate module names.
        'vendor.mediatek.hardware.mtkpower@1.0',
        'vendor.mediatek.hardware.mtkpower@1.1',
        'vendor.mediatek.hardware.mtkpower@1.2',
        'vendor.mediatek.hardware.mtkpower-V2-ndk',
        'vendor.mediatek.hardware.mtkpower_applist-V2-ndk',
        'vendor.mediatek.hardware.apuware.apusys-V5-ndk',
        'vendor.mediatek.hardware.apuware.utils-V1-ndk',
        'vendor.mediatek.hardware.apuware.xrp-V1-ndk',
        'vendor.tsa.hdcp-V1-ndk',
    ): lib_fixup_vendor_suffix,
}

blob_fixups: blob_fixups_user_type = {
    'system_ext/bin/hw/motorola.hardware.tcmdaidl-service': blob_fixup()
        .remove_needed('libandroidicu.so'),
    'vendor/bin/hw/wpa_supplicant': blob_fixup()
        .replace_needed(
            'android.hardware.wifi.supplicant-V3-ndk.so',
            'android.hardware.wifi.supplicant-V4-ndk.so',
        ),
    'vendor/bin/hw/hostapd': blob_fixup()
        .replace_needed(
            'android.hardware.wifi.hostapd-V2-ndk.so',
            'android.hardware.wifi.hostapd-V3-ndk.so',
        )
        .remove_needed('android.hardware.wifi.common-V1-ndk.so'),
    'vendor/bin/hw/android.hardware.wifi-service-lazy': blob_fixup()
        .replace_needed(
            'android.hardware.wifi-V2-ndk.so',
            'android.hardware.wifi-V3-ndk.so',
        ),
    'vendor/lib64/libmtkcam_hal_aidl_common.so': blob_fixup()
        .replace_needed('android.hardware.camera.common-V2-ndk.so', 'android.hardware.camera.common-V1-ndk.so'),
    # The stock firmware ships a proprietary android.hardware.power-service-
    # mediatek.so that implements IPower @5 (DT_NEEDED: power-V5-ndk).  The
    # LineageOS source tree also builds a library of the same name, but it
    # implements @2 and ships power-mtk.xml (@2) which conflicts with the
    # proprietary power-mediatek.xml (@5) and is too old for FCM level 202404
    # (requires @5+).  By extracting the proprietary blob the auto-generated
    # Android.bp creates a cc_prebuilt_library_shared with prefer:true that
    # overrides the source module — so power-mtk.xml is NOT installed and no
    # conflict occurs.  The source module links power-V2-ndk; Soong forbids
    # a module from depending on multiple AIDL versions, so the prebuilt must
    # also use V2.  The proprietary blob was compiled against V5 but only
    # references V1-V2 symbols (verified via check_elf_file), so V5->V2 is
    # safe.
    'vendor/lib64/android.hardware.power-service-mediatek.so': blob_fixup()
        .replace_needed('android.hardware.power-V5-ndk.so', 'android.hardware.power-V2-ndk.so'),
    'vendor/bin/hw/vendor.mediatek.hardware.mtkpower-service.mediatek': blob_fixup()
        .replace_needed('android.hardware.power-V5-ndk.so', 'android.hardware.power-V2-ndk.so'),
    'vendor/bin/hw/android.hardware.sensors-service.multihal': blob_fixup()
        .replace_needed('android.hardware.sensors-V2-ndk.so', 'android.hardware.sensors-V3-ndk.so'),
    (
        'vendor/lib/libsensorndkbridge.so',
        'vendor/lib64/libsensorndkbridge.so',
        'vendor/lib/libaalservice.so',
        'vendor/lib64/libaalservice.so',
        'vendor/lib/libcam.utils.sensorprovider.so',
        'vendor/lib64/libcam.utils.sensorprovider.so',
        'vendor/bin/mnld',
    ): blob_fixup()
        .remove_needed('android.hardware.sensors-V2-ndk.so'),
    'system_ext/lib64/libimsma.so': blob_fixup()
        .replace_needed('libsink.so', 'libsink-mtk.so'),
    (
        'vendor/bin/hw/android.hardware.audio.service-aidl.mediatek',
        'vendor/lib64/hw/android.hardware.soundtrigger3-impl.so',
    ): blob_fixup()
        .replace_needed('libaudio_aidl_conversion_common_ndk.so', 'libaudio_aidl_conversion_common_ndk_prebuilt.so'),
    'vendor/lib64/android.hardware.audio.core-impl-mediatek.so': blob_fixup()
        .replace_needed('libaudio_aidl_conversion_common_ndk.so', 'libaudio_aidl_conversion_common_ndk_prebuilt.so'),
    (
        'vendor/lib64/hw/android.hardware.audio.effect.aidl-impl-mediatek.so',
        'vendor/lib64/hw/hwcomposer.mt6893.so',
        'vendor/lib64/hw/vendor.mediatek.hardware.pq_aidl-impl.so',
        'vendor/lib64/libpqxmlparser.so',
        'vendor/lib64/librt_extamp_intf.so',
        'vendor/lib64/libsilkybrightnesscore.so'
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v34.so'),
    (
        'vendor/lib64/egl/libGLES_mali.so',
        'vendor/lib/egl/libGLES_mali.so',
        'vendor/lib64/libgpud.so',
        'vendor/lib/libgpud.so',
        'vendor/lib64/libmtkcam_grallocutils.so',
        'vendor/lib64/libcodec2_fsr.so',
        'vendor/lib64/libgralloctypes.so',
        'vendor/lib64/hw/mapper.mediatek.so',
        'vendor/lib64/hw/android.hardware.graphics.allocator-V2-mediatek.so',
        'vendor/bin/hw/android.hardware.graphics.allocator-V2-service-mediatek',
        'vendor/lib64/vendor.mediatek.hardware.pq_aidl-V2-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.pq_aidl-V4-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.camera.isphal-V1-ndk.so',
        'vendor/lib/libcodec2_fsr.so',
        'vendor/lib/libgralloctypes.so',
        'vendor/lib/vendor.mediatek.hardware.pq_aidl-V2-ndk.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.common-V5-ndk.so', 'android.hardware.graphics.common-V6-ndk.so'),
    'vendor/lib64/vendor.mediatek.hardware.pq_aidl-V7-ndk.so': blob_fixup()
        .replace_needed('android.hardware.graphics.common-V4-ndk.so', 'android.hardware.graphics.common-V6-ndk.so'),
    # libneuralnetworks_sl_driver_mtk_legacy_prebuilt.so was linked against the
    # versioned NDK stub libnativewindow (symbols carry @LIBNATIVEWINDOW). The
    # AOSP LLNDK vendor variant libnativewindow.vendor.so is built unversioned
    # (llndk.unversioned=true), so check_elf_file cannot match the versioned
    # references and fails the build. At runtime the blob loads the versioned
    # /system/lib64/libnativewindow.so, so clearing the version node is safe:
    # unversioned references resolve against both the unversioned vendor
    # variant (build-time check) and the versioned system lib (runtime).
    'vendor/lib64/libneuralnetworks_sl_driver_mtk_legacy_prebuilt.so': blob_fixup()
        .clear_symbol_version('AHardwareBuffer_allocate')
        .clear_symbol_version('AHardwareBuffer_createFromHandle')
        .clear_symbol_version('AHardwareBuffer_describe')
        .clear_symbol_version('AHardwareBuffer_getNativeHandle')
        .clear_symbol_version('AHardwareBuffer_lock')
        .clear_symbol_version('AHardwareBuffer_release')
        .clear_symbol_version('AHardwareBuffer_unlock'),
    # libneuron_adapter_mgvi.so has the same @LIBNATIVEWINDOW versioned
    # reference problem as libneuralnetworks_sl_driver_mtk_legacy_prebuilt.so
    # above (check_elf_file fails on AHardwareBuffer_describe/lock/unlock).
    # Clearing the version nodes is safe for the same reason: at runtime the
    # blob resolves against the versioned /system/lib64/libnativewindow.so.
    # Only the 64-bit variant is extracted: the 32-bit stock blob has a broken
    # DT_STRTAB (virtual address not in any segment), so its dependencies can
    # never be inferred and check_elf_file would always fail. Nothing links
    # against the 32-bit variant via DT_NEEDED (verified with readelf).
    'vendor/lib64/mt6893/libneuron_adapter_mgvi.so': blob_fixup()
        .clear_symbol_version('AHardwareBuffer_describe')
        .clear_symbol_version('AHardwareBuffer_lock')
        .clear_symbol_version('AHardwareBuffer_unlock'),

}  # fmt: skip

module = ExtractUtilsModule(
    'lyriq',
    'motorola',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
