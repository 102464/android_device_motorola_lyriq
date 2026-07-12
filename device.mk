#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Enforce generic ramdisk allow list
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Virtual A/B Compression (VABC) - T launching device with init_boot.
# android_t_baseline.mk -> vabc_features.mk enables:
#   ro.virtual_ab.enabled/compression.enabled/userspace.snapshots.enabled/
#   batch_writes/io_uring.enabled/compression.xor.enabled = true
# and packages snapuserd (vendor_ramdisk + recovery variants).
# snapuserd_ramdisk for the generic ramdisk (init_boot) is provided by
# generic_ramdisk.mk above. Do NOT also inherit launch_with_vendor_ramdisk.mk
# or compression.mk to avoid conflicting/duplicate configuration.
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/android_t_baseline.mk)

# Project ID Quota
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

DEVICE_PATH := device/motorola/lyriq

# Boot control HAL for Virtual A/B
PRODUCT_PACKAGES += \
    com.android.hardware.boot \
    android.hardware.boot-service.default_recovery

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
# recovery ramdisk from vendor_boot and does NOT load init_boot (generic ramdisk).
# vabc_features.mk only packages snapuserd into the generic ramdisk (init_boot)
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

PRODUCT_PACKAGES += \
    android.hardware.audio.common-util \
    libalsautils \
    libopus.vendor \
    audioclient-types-aidl-cpp.vendor \
    MtkInCallService

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

# API
PRODUCT_SHIPPING_API_LEVEL := 33
BOARD_SHIPPING_API_LEVEL := 30

# Fastboot
PRODUCT_PACKAGES += \
    android.hardware.fastboot-service.example_recovery \
    fastbootd

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.mediatek \
    android.hardware.health-service.mediatek-recovery

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
    init.oem.hw.sh \
    init.project.rc \
    init.sensor_2_0.rc \
    ueventd.mt6893.rc

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH) \
    hardware/mediatek \
    hardware/mediatek/libmtkperf_client

# USB
PRODUCT_PACKAGES += \
    android.hardware.usb-service.mediatek \
    android.hardware.usb.gadget-service.mediatek

# Inherit the proprietary files
$(call inherit-product, vendor/motorola/lyriq/lyriq-vendor.mk)
