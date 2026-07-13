#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Device uses AIDL CAS HAL (com.android.hardware.cas APEX) instead of
# deprecated HIDL CAS 1.2 service. Set this before inheriting base products,
# where build/target/product/base_vendor.mk decides default vendor packages.
TARGET_REQUIRES_HIDL_CAS_HAL := false

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

# Inherit from lyriq device
$(call inherit-product, device/motorola/lyriq/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_DEVICE := lyriq
PRODUCT_NAME := lineage_lyriq
PRODUCT_BRAND := motorola
PRODUCT_MODEL := motorola edge 40
PRODUCT_MANUFACTURER := motorola

PRODUCT_GMS_CLIENTID_BASE := android-motorola

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="lyriq_g-user 15 V1TLS35M.73-60-3-9 788c2e release-keys" \
    BuildFingerprint=motorola/lyriq_g/lyriq:15/V1TLS35M.73-60-3-9/788c2e:user/release-keys
