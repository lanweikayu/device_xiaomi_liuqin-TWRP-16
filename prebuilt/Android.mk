LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := recovery_prebuilt
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)
LOCAL_HOST_REQUIRED_MODULES := depmod
LOCAL_REQUIRED_MODULES := \
    android.hardware.boot-service.qti_recovery \
    android.hardware.boot-service.default_recovery
LOCAL_POST_INSTALL_CMD += \
    sh $(LOCAL_PATH)/recovery_post_install.sh $(TARGET_RECOVERY_ROOT_OUT) $(LOCAL_PATH) $(DEPMOD)
include $(BUILD_PHONY_PACKAGE)

# Overwrite AOSP misc-based boot HAL with QTI GPT-based impl after both are installed.
include $(CLEAR_VARS)
LOCAL_MODULE := bootctrl_qti_as_default
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)
LOCAL_REQUIRED_MODULES := android.hardware.boot@1.2-impl-qti.recovery
LOCAL_POST_INSTALL_CMD := \
    mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/system/lib64/hw; \
    if [ -f $(TARGET_RECOVERY_ROOT_OUT)/system/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so ]; then \
        cp -f $(TARGET_RECOVERY_ROOT_OUT)/system/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so \
              $(TARGET_RECOVERY_ROOT_OUT)/system/lib64/hw/android.hardware.boot@1.0-impl-1.2.so; \
    elif [ -f $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so ]; then \
        cp -f $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so \
              $(TARGET_RECOVERY_ROOT_OUT)/system/lib64/hw/android.hardware.boot@1.0-impl-1.2.so; \
    fi
include $(BUILD_PHONY_PACKAGE)
