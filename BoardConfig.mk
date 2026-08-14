#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/motorola/lyriq
KERNEL_PATH := device/motorola/lyriq-kernel

# SELinux (MTK declarations must precede lyriq rules that reference them)
include device/mediatek/sepolicy_vndr/SEPolicy.mk

BOARD_VENDOR_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy/vendor

SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy/private

# A/B
AB_OTA_PARTITIONS := \
    boot \
    dtbo \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

BUILD_BROKEN_DUP_RULES := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a55

# Boot image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_RAMDISK_USE_LZ4 := true
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true
BOARD_INCLUDE_DTB_IN_BOOTIMG := true

BOARD_KERNEL_CMDLINE += bootopt=64S3,32N2,64N2
BOARD_KERNEL_CMDLINE += androidboot.bootdevice=11270000.ufshci

BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x11088000
BOARD_KERNEL_TAGS_OFFSET := 0x07c08000
BOARD_DTB_OFFSET := 0x07c08000

BOARD_MKBOOTIMG_ARGS += \
    --dtb_offset $(BOARD_DTB_OFFSET) \
    --header_version $(BOARD_BOOT_HEADER_VERSION) \
    --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)

# init_boot is not used: Motorola bootloader denies fastboot flash to the
# init_boot partition ("flash permission denied"). The generic ramdisk
# (first_stage init, snapuserd, etc.) is therefore packed into boot.img
# instead. AOSP Makefile automatically adds --ramdisk to boot.img when
# BUILDING_INIT_BOOT_IMAGE is not true.

# Kernel
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(KERNEL_PATH)/Image.gz

# Kill lineage kernel build task while preserving kernel
TARGET_NO_KERNEL_OVERRIDE := true

# Workaround to make lineage's soong generator work
TARGET_KERNEL_SOURCE := device/motorola/lyriq-kernel/kernel-headers

# Board Info
TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt

# DTB
BOARD_PREBUILT_DTBIMAGE_DIR := $(KERNEL_PATH)/dtb
BOARD_MKBOOTIMG_ARGS += --dtb $(BOARD_PREBUILT_DTBIMAGE_DIR)/mt6893.dtb

# DTBO
BOARD_PREBUILT_DTBOIMAGE := $(KERNEL_PATH)/dtbo.img

BOARD_SYSTEM_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/system/*.ko)
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules.load.system))
BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/vendor/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules.load.vendor))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/vendor_ramdisk/*.ko)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules.load.vendor_ramdisk))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules.load.recovery))
BOOT_KERNEL_MODULES := $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD) $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD)

# Bootloader
TARGET_NO_BOOTLOADER := true

# Display
TARGET_SCREEN_DENSITY := 400

# Filesystem
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/configs/mot_aids.fs

# VINTF
# Stock vendor/etc/vintf/manifest.xml declares all device HALs (camera provider,
# radio, MTK HALs, trustonic, etc.) with target-level="202404" (Android 15).
# Stock vendor/etc/vintf/compatibility_matrix.xml requires framework HALs like
# android.frameworks.sensorservice. Both are copied from stock firmware.
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/configs/vintf/manifest.xml
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/configs/vintf/manifest_keymint_rkp.xml
DEVICE_MATRIX_FILE := $(DEVICE_PATH)/configs/vintf/compatibility_matrix.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    $(DEVICE_PATH)/configs/vintf/framework_compatibility_matrix.xml
DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE += \
    $(DEVICE_PATH)/configs/vintf/product_framework_compatibility_matrix.xml

# Stock ODM VINTF manifests
ODM_MANIFEST_FILES += \
    vendor/motorola/lyriq/proprietary/odm/etc/vintf/manifest_b.xml \
    vendor/motorola/lyriq/proprietary/odm/etc/vintf/manifest_bn.xml \
    vendor/motorola/lyriq/proprietary/odm/etc/vintf/manifest_d.xml \
    vendor/motorola/lyriq/proprietary/odm/etc/vintf/manifest_de.xml \
    vendor/motorola/lyriq/proprietary/odm/etc/vintf/manifest_dn.xml

# Stock vendor VINTF manifest fragments
DEVICE_MANIFEST_FILE += \
    vendor/motorola/lyriq/proprietary/vendor/etc/vintf/manifest/CommandService.xml \
    vendor/motorola/lyriq/proprietary/vendor/etc/vintf/manifest/dms-service.xml \
    vendor/motorola/lyriq/proprietary/vendor/etc/vintf/manifest/manifest_apuware_apusys_aidl.xml \
    vendor/motorola/lyriq/proprietary/vendor/etc/vintf/manifest/manifest_apuware_utils_aidl.xml \
    vendor/motorola/lyriq/proprietary/vendor/etc/vintf/manifest/manifest_apuware_xrp_aidl.xml \
    vendor/motorola/lyriq/proprietary/vendor/etc/vintf/manifest/manifest_rcs.xml \
    vendor/motorola/lyriq/proprietary/vendor/etc/vintf/manifest/motorola.hardware.audio.radar2.xml

# Partitions
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_SUPER_PARTITION_SIZE := 9126805504

BOARD_SUPER_PARTITION_GROUPS := motorola_dynamic_partitions
BOARD_MOTOROLA_DYNAMIC_PARTITIONS_PARTITION_LIST += \
    product \
    system \
    system_dlkm \
    system_ext \
    vendor \
    vendor_dlkm

BOARD_MOTOROLA_DYNAMIC_PARTITIONS_SIZE := 9122611200

BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

TARGET_COPY_OUT_ODM := vendor/odm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_USES_VENDOR_DLKMIMAGE := true

BOARD_USES_METADATA_PARTITION := true

# Platform
TARGET_BOARD_PLATFORM := mt6893
TARGET_USES_VULKAN := false

# Vendor properties
# configs/props/vendor.prop contains ~400 hardware properties extracted from
# stock vendor/build.prop (MTK platform, camera, GPU, gralloc, audio, Dolby,
# PQ, radio, etc.). The build system (sysprop.mk) merges this file into
# vendor/build.prop via the build-properties macro. Duplicates are resolved
# last-one-wins, so PRODUCT_VENDOR_PROPERTIES still overrides these.
TARGET_VENDOR_PROP := $(DEVICE_PATH)/configs/props/vendor.prop

# Recovery
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 165
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/init/fstab.mt6893
TARGET_USERIMAGES_USE_F2FS := true

# SPL
BOOT_SECURITY_PATCH := 2026-04-01
VENDOR_SECURITY_PATCH := 2026-04-01

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_ALGORITHM := SHA256_RSA4096
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag
BOARD_AVB_ROLLBACK_INDEX := 25

BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := 25
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

# Inherit the proprietary files
include vendor/motorola/lyriq/BoardConfigVendor.mk
