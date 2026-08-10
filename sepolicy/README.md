# SELinux Policy (sepolicy/)

This directory contains device-specific SELinux policy for Motorola Edge 40 (lyriq).
All rules are extracted from stock vendor/system_ext CIL and converted to .te format.

## Directory Structure

### vendor/ (BOARD_VENDOR_SEPOLICY_DIRS)

Policy for the vendor partition. Files are processed alphabetically by checkpolicy;
type declarations must appear before typeattribute use in later files.

**Type declarations:**
- `stock_types.te` - All stock type declarations extracted from vendor CIL
  (property types, file types, service types, device types, sysfs types)
- `hal_attributes.te` - HAL attribute declarations for device-specific HALs

**Contexts files:**
- `file_contexts` - Vendor file labels (binaries, devices, data dirs)
- `property_contexts` - Vendor property labels
- `service_contexts` - Vendor service manager labels
- `hwservice_contexts` - Vendor hwservicemanager labels
- `genfs_contexts` - genfscon entries (proc, sysfs, debugfs)

**Per-domain rules (one .te per domain):**
Files named `<domain>.te` contain rules for that domain only.
Examples: `hal_fingerprint_default.te`, `mtk_hal_wifi.te`, `wpa.te`

**Cross-domain / batch rule files:**
- `stock_prop_rules.te` - Property read rules sourced from stock CIL
- `mnt_vendor_search.te` - mnt_vendor_file:dir search for vendor domains
- `service_finds.te` - service_manager find rules across domains
- `functional_gaps.te` - Functional rule gaps from avtab diff (eSIM, GPS, etc.)
- `generic_parity.te` - AOSP flag-gated generic rules stock enables

**Attribute fix files (zzz_ prefix for alphabetical ordering after stock_types.te):**
- `zzz_mot_core_prop.te` - mot_core_property_type attribute and read access
- `zzz_prop_attrs.te` - Missing property type attributes (mtk_core_property_type,
  vendor_restricted_property_type, vendor_internal_property_type) and broad
  allow-domain read rules for Moto public props

**MLS compatibility:**
- `mls_compat.te` - mlstrustedobject/subject attributes for MLS constraint exemption
  (gralloc memfd, apusys_device, etc. -- stock parity, required for enforcing)

### private/ (SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS)

Policy for the system_ext partition.
- `mot_radio.te` - Motorola radio extension service declarations
- `mot_system.te` - Motorola system services (motsettings, moto_ext_telephony, etc.)
- `audio_parameter_parser.te` - Audio parameter parser domain
- `property_contexts` - system_ext property labels
- `service_contexts` - system_ext service labels
- `file_contexts` - system_ext file labels

## Rule Sourcing

All rules are verified against stock policy binary using neverallow probes
(`sepolicy-analyze <binary> neverallow -f <probe.te>`). Rules that stock grants
via attributes (e.g., `mtk_core_property_type`, `mot_core_property_type`) are
replicated using the same attribute mechanism rather than per-domain allow rules.

## Known Unfixable Gaps

These gaps exist in stock but cannot be expressed in vendor policy due to
AOSP neverallow constraints or plat-private type visibility:

- `task_profiles_api_file:file read` - AOSP domain.te neverallow blocks some domains
- `mtk_hal_mali_platform_default_service:service_manager find` - hal_attribute_service
  neverallow limits find to hal_mtk_mali_platform_client only
- `radio -> system_mtk_*_prop:property_service set` - target types in plat_private
- `radio -> mtk_carrierexpress_service:service_manager add` - target type in MTK plat_private
- `system_suspend -> tee:binder transfer` - system_suspend is plat-private domain
