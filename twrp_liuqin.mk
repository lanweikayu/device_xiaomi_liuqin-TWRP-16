#
# Copyright (C) 2023 The Android Open Source Project
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_RELEASE_NAME := liuqin

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, device/xiaomi/liuqin/device.mk)
$(call inherit-product, vendor/twrp/config/common.mk)

PRODUCT_DEVICE := liuqin
PRODUCT_NAME := twrp_liuqin
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := Xiaomi Pad 6 Pro
PRODUCT_MANUFACTURER := Xiaomi

# Physical panel is 1800x2880. Landscape UI is rotated to 2880x1800.
ifeq ($(USE_PORTRAIT),true)
TARGET_SCREEN_WIDTH := 1800
TARGET_SCREEN_HEIGHT := 2880
else
TARGET_SCREEN_WIDTH := 2880
TARGET_SCREEN_HEIGHT := 1800
endif
TARGET_SCREEN_DENSITY := 360
TW_FRAMERATE := 120

# Load these from ramdisk first so touch/display work without a mounted vendor.
TW_LOAD_VENDOR_MODULES := "qcom_wdt_core.ko gh_virt_wdt.ko clk-rpmh.ko gcc-waipio.ko dispcc-waipio.ko pinctrl-cape.ko hwkm.ko tmecom-intf.ko crypto-qti-common.ko crypto-qti-hwkm.ko ufshcd-crypto-qti.ko phy-qcom-ufs.ko phy-qcom-ufs-qmp-v4-cape.ko qcom-reboot-reason.ko ufs_qcom.ko adsp_loader_dlkm.ko xiaomi_touch.ko nt36532_touch.ko msm_drm.ko qti_battery_charger_main_m81.ko"
TW_LOAD_PREBUILT_MODULES_AT_FIRST := true
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true

TW_NO_HAPTICS := true
