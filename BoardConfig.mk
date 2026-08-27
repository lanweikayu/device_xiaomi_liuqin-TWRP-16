#
# Copyright (C) 2023 The Android Open Source Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/liuqin

ALLOW_MISSING_DEPENDENCIES := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a75

ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# Bootloader / platform
PRODUCT_PLATFORM := taro
TARGET_BOOTLOADER_BOARD_NAME := taro
TARGET_NO_BOOTLOADER := true
TARGET_USES_UEFI := true
TARGET_BOARD_PLATFORM := taro
TARGET_BOARD_PLATFORM_GPU := qcom-adreno730
QCOM_BOARD_PLATFORMS += taro

# Kernel (prebuilt from current slot boot.img)
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_KERNEL_CMDLINE += disable_dma32=on
BOARD_KERNEL_CMDLINE += androidboot.hardware=qcom
BOARD_KERNEL_CMDLINE += androidboot.memcg=1
BOARD_KERNEL_CMDLINE += androidboot.usbcontroller=a600000.dwc3
BOARD_RAMDISK_USE_LZ4 := true
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_VERSION := 5.10
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
# Header v4 recovery on this ABL must not carry a kernel (see reference
# recovery.img: kernel_size=0). ABL uses boot.img kernel + vendor_boot.
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

# A/B + dedicated recovery
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    recovery \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

TARGET_OTA_ASSERT_DEVICE := liuqin

# AVB
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Partition sizes (measured from device)
BOARD_BOOTIMAGE_PARTITION_SIZE := 201326592
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 9122611200
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor vendor_dlkm odm

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

BOARD_ROOT_EXTRA_FOLDERS := bluetooth dsp firmware persist metadata
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_USES_METADATA_PARTITION := true

# Init
TARGET_INIT_VENDOR_LIB := //$(DEVICE_PATH):libinit_liuqin
TARGET_RECOVERY_DEVICE_MODULES := libinit_liuqin

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab
TARGET_RECOVERY_QCOM_RTC_FIX := true

# Crypto (FBE + metadata / wrappedkey)
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2
PLATFORM_VERSION := 16
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
# Future-proof test: TEE patch far ahead of any ColorOS key so begin()
# returns KEY_REQUIRES_UPGRADE and upgradeKey rewrites the blob in RAM
# only (TWRP does not persist it). ROM date overlays must not pull this
# back down or the upgrade path never runs.
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
BOOT_SECURITY_PATCH := 2099-12-31
TW_KEEP_VENDOR_SECURITY_PATCH := true
TW_KEEP_SYSTEM_SECURITY_PATCH := true

# Tools
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_EXCLUDE_LPDUMP := true
TW_INCLUDE_LPTOOLS := true
TW_EXCLUDE_TZDATA := true
# Metadata FBE keeps /dev/block/mapper/userdata on top of userdata. Format Data
# mkfs.f2fs then fails with "In use by the system!" unless that dm node is
# deleted first. TW_USE_DMCTL makes TWRP run `dmctl delete userdata` and ships
# dmctl in the ramdisk. Do not confuse with super Unmap_Super_Devices().
TW_USE_DMCTL := true
# Do not parse ROM vendor fstab (would require mounting super vendor).
TW_SKIP_ADDITIONAL_FSTAB := true
TW_FORCE_KEYMASTER_VER := true

# TWRP UI / device
# Panel is portrait-native 1800x2880. Landscape TWRP rotates the UI 90° so
# the theme sees 2880x1800, and touch axes follow that rotation.
# Default: landscape. Portrait (verified): USE_PORTRAIT=true
ifeq ($(USE_PORTRAIT),true)
TW_THEME := portrait_hdpi
TW_ROTATION := 0
else
TW_THEME := landscape_hdpi
TW_ROTATION := 90
RECOVERY_TOUCHSCREEN_SWAP_XY := true
RECOVERY_TOUCHSCREEN_FLIP_Y := true
endif
TW_DEVICE_VERSION := liuqin
RECOVERY_SDCARD_ON_DATA := true
BOARD_HAS_NO_REAL_SDCARD := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_EXTRA_LANGUAGES := true
# Drop Advanced WLAN + Extension (ttyd/microhttpd) and nano/bash.
TW_NO_NETWORK := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_BASH := true
TW_INCLUDE_NTFS_3G := true
TARGET_USES_MKE2FS := true
TW_USE_TOOLBOX := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 4095
TW_DEFAULT_BRIGHTNESS := 200
ifeq ($(TW_DEFAULT_LANGUAGE),)
TW_DEFAULT_LANGUAGE := zh_CN
endif
TW_NO_SCREEN_BLANK := true
TW_EXCLUDE_APEX := true
TW_HAS_EDL_MODE := false
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone27/temp"
TW_BACKUP_EXCLUSIONS := /data/fonts,/data/adb/ap,/data/adb/ksu
TW_STATUS_ICONS_ALIGN := center
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true

# Kernel modules (must be BoardConfig so recovery Android.mk sees them)
TW_LOAD_VENDOR_MODULES := "qcom_wdt_core.ko gh_virt_wdt.ko clk-rpmh.ko gcc-waipio.ko dispcc-waipio.ko pinctrl-cape.ko hwkm.ko tmecom-intf.ko crypto-qti-common.ko crypto-qti-hwkm.ko ufshcd-crypto-qti.ko phy-qcom-ufs.ko phy-qcom-ufs-qmp-v4-cape.ko qcom-reboot-reason.ko ufs_qcom.ko adsp_loader_dlkm.ko xiaomi_touch.ko nt36532_touch.ko msm_drm.ko qti_battery_charger_main_m81.ko"
TW_LOAD_PREBUILT_MODULES_AT_FIRST := true
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_NO_HAPTICS := true
TW_FRAMERATE := 120

# Debug
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true

# Recovery-only QTI boot HAL rules (ufs-bsg + GPT LUNs). Does not change
# the running OS vendor policy (wrapped in recovery_only).
BOARD_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy

# TWRP 16 prefers AIDL IBootControl. Replace AOSP misc-based default_recovery
# with the QTI GPT/UFS implementation after all modules are installed.
define liuqin-replace-aidl-boot-hal
	sh $(DEVICE_PATH)/prebuilt/replace_boot_hal.sh $(TARGET_RECOVERY_ROOT_OUT)
endef
BOARD_RECOVERY_IMAGE_PREPARE += $(call liuqin-replace-aidl-boot-hal)
