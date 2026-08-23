#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Device uses AIDL CAS HAL (com.android.hardware.cas APEX) instead of
# deprecated HIDL CAS 1.2 service. Set this before inheriting base products,
# where build/target/product/base_vendor.mk decides default vendor packages.
TARGET_REQUIRES_HIDL_CAS_HAL := false
PRODUCT_HIDL_ENABLED := true

# Sign with private keys so ro.build.tags=release-keys; the Trustonic
# mcDriverDaemon only loads tzapps from the signed tee partition (like stock)
# when the build is not tagged test-keys.
PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey

# config.mk only points MAINLINE_BLUETOOTH_SEPOLICY_DEV_CERTIFICATES at the
# release keys for com.google.android.bt; with AOSP com.android.bt it falls
# back to the AOSP default dir, so the BT signer in mac_permissions.xml
# mismatches the APEX key and com.android.bluetooth stays in the zygote
# domain (SELinux denials on bluetooth_data_file -> "Bluetooth keeps
# stopping"). Point it at the release bluetooth key explicitly.
PRODUCT_MAINLINE_BLUETOOTH_SEPOLICY_DEV_CERTIFICATES := vendor/lineage-priv/keys

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from lyriq device
$(call inherit-product, device/motorola/lyriq/device.mk)

# Inherit some common PixelOS stuff.
$(call inherit-product, vendor/custom/config/common_full_phone.mk)

PRODUCT_DEVICE := lyriq
PRODUCT_NAME := custom_lyriq
PRODUCT_BRAND := motorola
PRODUCT_MODEL := motorola edge 40
PRODUCT_MANUFACTURER := motorola

PRODUCT_GMS_CLIENTID_BASE := android-motorola

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="lyriq_g-user 15 V1TLS35M.73-60-3-9 788c2e release-keys" \
    BuildFingerprint=motorola/lyriq_g/lyriq:15/V1TLS35M.73-60-3-9/788c2e:user/release-keys
