#
# Copyright (C) 2023 The Android Open Source Project
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/xiaomi/liuqin

PRODUCT_USE_DYNAMIC_PARTITIONS := true
ENABLE_VIRTUAL_AB := true

TW_INCLUDE_FASTBOOTD := true

PRODUCT_SHIPPING_API_LEVEL := 31
PRODUCT_TARGET_VNDK_VERSION := 33

PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl-qti.recovery \
    android.hardware.boot-service.qti_recovery \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

PRODUCT_EXTRA_RECOVERY_KEYS += \
    $(LOCAL_PATH)/security/miui_releasekey

PRODUCT_PROPERTY_OVERRIDES += \
    ro.twrp.device.name=$(PRODUCT_RELEASE_NAME) \
    keymaster_ver=4.1 \
    ro.hardware.keystore_desede=true \
    ro.boot.boot_security_patch=2099-12-31 \
    persist.twrp.rotation=90 \
    ro.recovery.usb.vid=18D1 \
    ro.recovery.usb.adb.pid=4EE7 \
    ro.recovery.usb.fastboot.pid=D00D

TWRP_REQUIRED_MODULES += recovery_prebuilt bootctrl_qti_as_default android.hardware.boot-service.qti_recovery
