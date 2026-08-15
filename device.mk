#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Enforce generic ramdisk allow list
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Virtual A/B Compression (VABC) - T launching device.
# android_t_baseline.mk -> vabc_features.mk enables:
#   ro.virtual_ab.enabled/compression.enabled/userspace.snapshots.enabled/
#   batch_writes/io_uring.enabled/compression.xor.enabled = true
# and packages snapuserd (vendor_ramdisk + recovery variants).
# snapuserd_ramdisk for the generic ramdisk (packed into boot.img since
# this device does not use init_boot) is provided by generic_ramdisk.mk
# above. Do NOT also inherit launch_with_vendor_ramdisk.mk or
# compression.mk to avoid conflicting/duplicate configuration.
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/android_t_baseline.mk)

# Project ID Quota
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

DEVICE_PATH := device/motorola/lyriq

# adb authorized keys, installed to /product/etc/security/adb_keys and
# exposed to adbd via the /adb_keys symlink (debuggable builds only).
PRODUCT_ADB_KEYS := $(DEVICE_PATH)/init/lyriq_adb_keys

# Recovery Boot control HAL for Virtual A/B
PRODUCT_PACKAGES += \
    android.hardware.boot-service.default_recovery \
    hwservicemanager \
    vndservicemanager

# VABC compression method: determined from stock firmware analysis.
# Stock vendor/build.prop: ro.virtual_ab.compression.enabled=true,
#   ro.virtual_ab.compression.xor.enabled=true,
#   ro.virtual_ab.compression.threads=true
# Stock snapuserd binary (from vendor_boot recovery ramdisk) supports:
#   lz4, brotli, zstd, uncompressed (does NOT include gz)
# No OTA package or COW header available to confirm the exact algorithm.
# Using lz4: matches Google Cuttlefish reference (device/google/cuttlefish),
# supported by both stock and AOSP snapuserd, fast decompression, and is the
# most common VABC compression in Android 14/15.
PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4

# Copy prebuilt kernel to output directory.
# TARGET_NO_KERNEL_OVERRIDE := true in BoardConfig skips
# vendor/lineage/build/tasks/kernel.mk entirely, which means the rule
# that copies TARGET_PREBUILT_KERNEL to $(PRODUCT_OUT)/kernel is never
# defined. Without this rule, bootimage build fails after installclean
# because the kernel file is removed and not recreated.
PRODUCT_COPY_FILES += device/motorola/lyriq-kernel/Image.gz:kernel

# snapuserd.recovery is required because this device uses
# BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT, meaning Recovery loads the
# recovery ramdisk from vendor_boot and does NOT load boot.img's generic ramdisk.
# vabc_features.mk only packages snapuserd into the generic ramdisk (boot.img)
# and the system image; the recovery ramdisk needs its own copy so that Recovery
# can handle VABC snapshots. snapuserd is a static_executable, so no extra
# shared libraries are needed.
PRODUCT_PACKAGES += \
    snapuserd.recovery

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

PRODUCT_PACKAGES += \
    otapreopt_script

PRODUCT_PACKAGES += \
    e2fsck.vendor_ramdisk \
    fsck.f2fs.vendor_ramdisk \
    linker.vendor_ramdisk \
    resize2fs.vendor_ramdisk \
    tune2fs.vendor_ramdisk

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

# Boot animation
TARGET_SCREEN_HEIGHT := 2400
TARGET_SCREEN_WIDTH := 1080

# Characteristics
PRODUCT_CHARACTERISTICS := nosdcard

# Device uses high-density artwork where available
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi

# Audio
$(call soong_config_set,android_hardware_audio,run_64bit,true)

# USB: lyriq ships the full stock init.mt6893.usb.rc; disable the generic
# mediatek gadget rc to avoid a duplicate module/install.
$(call soong_config_set,mediatek_gadget,use_custom_usb_gadget_rc,true)

PRODUCT_PACKAGES += \
    android.hardware.audio.common-util \
    libalsautils \
    libopus.vendor \
    audioclient-types-aidl-cpp.vendor \
    MtkInCallService

# AIDL effect libraries for audio_effects_config.xml
PRODUCT_PACKAGES += \
    libaecsw \
    libagc1sw \
    libagc2sw \
    libbassboostsw \
    libbundleaidl \
    libdownmixaidl \
    libdynamicsprocessingaidl \
    libequalizersw \
    libextensioneffect \
    libhapticgeneratoraidl \
    libloudnessenhanceraidl \
    libnssw \
    libpreprocessingaidl \
    libpresetreverbsw \
    libreverbaidl \
    libvirtualizersw \
    libvisualizeraidl \
    libvolumesw

PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/audio/,$(TARGET_COPY_OUT_VENDOR)/etc)

PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml

# Dalvik
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=24m \
    dalvik.vm.heapgrowthlimit=256m \
    dalvik.vm.heapsize=512m \
    dalvik.vm.heaptargetutilization=0.46 \
    dalvik.vm.heapminfree=8m \
    dalvik.vm.heapmaxfree=48m

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Vendor linker config (Widevine L1: liboemcrypto provideLibs, same as stock linker.config.pb)
PRODUCT_VENDOR_LINKER_CONFIG_FRAGMENTS += device/motorola/lyriq/configs/linker/vendor-linker.config.json

# API
PRODUCT_SHIPPING_API_LEVEL := 33
BOARD_SHIPPING_API_LEVEL := 30

# Fastboot
PRODUCT_PACKAGES += \
    android.hardware.fastboot-service.example_recovery \
    fastbootd

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.lyriq \
    android.hardware.health-service.lyriq-recovery

# Init
PRODUCT_PACKAGES += \
    fstab.mt6893 \
    fstab.mt6893.vendor_ramdisk \
    init.connectivity.rc \
    init.connectivity.common.rc \
    init_conninfra.rc \
    init.insmod.sh \
    init.mmi.overlay.rc \
    init.mmi.rc \
    init.modem.rc \
    init.mt6893.rc \
    init.mt6893.usb.rc \
    init.cgroup.rc \
    init.recovery.mt6893.rc \
    init.mtkgki.rc \
    init.project.rc \
    init.lyriq.fod_gesture.sh \
    init.sensor_2_0.rc \
    ueventd.mt6893.rc

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH) \
    hardware/mediatek \
    hardware/mediatek/libmtkperf_client

# USB
# The gadget HAL stays disabled until sys.usb.configfs=2, which the stock
# init.mt6893.usb.rc sets on boot; both are required together.
PRODUCT_PACKAGES += \
    android.hardware.usb-service.mediatek \
    android.hardware.usb.gadget-service.mediatek

# Device-specific resource overlays (IMS package binding, 144Hz peak refresh,
# display cutout, status bar and rounded corner dimens, edge-back gesture
# inset, eUICC slot declaration)
DEVICE_PACKAGE_OVERLAYS += $(DEVICE_PATH)/overlay

# Static RRO over AOSP CarrierConfig: converted stock carrier database
# (vendor.xml) + NR (5G) + VoLTE defaults
PRODUCT_PACKAGES += \
    LyriqCarrierConfigOverlay

# Telephony injection shim: plain AOSP components + MotoOemRIL companion
# (mtkfusionrild add-on channel, required for eSIM slot reporting)
PRODUCT_PACKAGES += \
    lyriq-telephony-shim \
    LyriqTelephonyInjectionOverlay

# GraphicBufferSource shim: restores the A15 getHGraphicBufferProducer()
# symbol removed by A16; loaded by the stock codec2 HIDL blobs
PRODUCT_PACKAGES += \
    libcodec2_gbs_shim

# eSIM (eUICC on slot 1, stock product props)
PRODUCT_PRODUCT_PROPERTIES += \
    ro.telephony.esim_slot_id=1 \
    esim.enable_esim_system_ui_by_default=true \
    ro.telephony.default_network=26,26

# Inherit the proprietary files
$(call inherit-product, vendor/motorola/lyriq/lyriq-vendor.mk)
