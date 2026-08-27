#!/bin/sh
# Called from BOARD_RECOVERY_IMAGE_PREPARE, after all recovery modules are
# installed and immediately before the ramdisk is packed.
set -e
ROOT="$1"
USE_PORTRAIT="${2:-}"
QTI_BOOT="$ROOT/system/bin/hw/android.hardware.boot-service.qti_recovery"
DEF_BOOT="$ROOT/system/bin/hw/android.hardware.boot-service.default_recovery"
if [ ! -f "$QTI_BOOT" ]; then
    echo "liuqin: missing QTI AIDL boot HAL at $QTI_BOOT" >&2
    exit 1
fi
if [ ! -f "$DEF_BOOT" ]; then
    echo "liuqin: missing default AIDL boot HAL at $DEF_BOOT" >&2
    exit 1
fi
echo "liuqin: installing QTI GPT boot HAL as default_recovery"
cp -f "$QTI_BOOT" "$DEF_BOOT"
chmod 0755 "$DEF_BOOT"

# TWRP's recovery copy of keystore2 / libminuitwrp can lag the rebuilt
# system image (portrait leftovers in ramdisk while theme xml is landscape).
KS_SRC="$ROOT/../../system/bin/keystore2"
if [ -f "$KS_SRC" ]; then
    echo "liuqin: installing rebuilt keystore2 into recovery ramdisk"
    cp -f "$KS_SRC" "$ROOT/system/bin/keystore2"
    chmod 0755 "$ROOT/system/bin/keystore2"
fi
MINUI_SRC="$ROOT/../../system/lib64/libminuitwrp.so"
if [ -f "$MINUI_SRC" ]; then
    echo "liuqin: installing rebuilt libminuitwrp into recovery ramdisk"
    mkdir -p "$ROOT/system/lib64"
    cp -f "$MINUI_SRC" "$ROOT/system/lib64/libminuitwrp.so"
    chmod 0755 "$ROOT/system/lib64/libminuitwrp.so"
fi
# AOSP recovery installs android.hardware.boot-service.default.xml
# (type="device") under /system/etc/vintf/manifest/. libvintf then
# fails the whole framework manifest:
#   Cannot add a device manifest to a framework manifest
# hwservicemanager sets hwservicemanager.disabled=true, HIDL
# keymaster/gatekeeper cannot register, and FBE decrypt fails.
SYS_VINTF="$ROOT/system/etc/vintf/manifest"
VEN_VINTF="$ROOT/vendor/etc/vintf/manifest"
mkdir -p "$VEN_VINTF"
if [ -d "$SYS_VINTF" ]; then
    for f in "$SYS_VINTF"/*.xml; do
        [ -f "$f" ] || continue
        if grep -q 'type="device"' "$f"; then
            echo "liuqin: moving device VINTF fragment $(basename "$f") to vendor"
            mv -f "$f" "$VEN_VINTF/"
        fi
    done
fi

# Keep AOSP seclabel (hal_bootctl_server must add IBootControl). GPT/UFS
# access comes from device sepolicy + label_bootctrl.sh.
BOOT_RC="$ROOT/system/etc/init/android.hardware.boot-service.default_recovery.rc"
mkdir -p "$ROOT/system/etc/init"
cat > "$BOOT_RC" <<'EOF'
service vendor.boot-default /system/bin/hw/android.hardware.boot-service.default_recovery
    class hal
    user root
    group root
    disabled
    seclabel u:r:hal_bootctl_default:s0
    interface aidl android.hardware.boot.IBootControl/default
EOF
echo "liuqin: installed enforcing boot HAL rc"
chmod 0755 "$ROOT/system/bin/label_bootctrl.sh" 2>/dev/null || true

# graphics.cpp prefers persist.twrp.rotation over compiled TW_ROTATION.
# Landscape forces 90; portrait must be 0 or the portrait theme still draws sideways.
ROTATION=90
if [ "$USE_PORTRAIT" = "true" ]; then
    ROTATION=0
fi
INIT_RC="$ROOT/init.recovery.qcom.rc"
if [ -f "$INIT_RC" ]; then
    sed -i "s/resetprop persist.twrp.rotation [0-9]*/resetprop persist.twrp.rotation $ROTATION/" "$INIT_RC"
    echo "liuqin: persist.twrp.rotation $ROTATION"
fi

# Crypto HALs must run from ramdisk /system/bin, not super vendor (pins vendor_a).
mkdir -p "$ROOT/system/bin/hw"
if [ -f "$ROOT/vendor/bin/qseecomd" ]; then
    echo "liuqin: copying qseecomd to /system/bin"
    cp -f "$ROOT/vendor/bin/qseecomd" "$ROOT/system/bin/qseecomd"
    chmod 0755 "$ROOT/system/bin/qseecomd"
fi
if [ -d "$ROOT/vendor/bin/hw" ]; then
    for bin in "$ROOT/vendor/bin/hw"/*; do
        [ -f "$bin" ] || continue
        echo "liuqin: copying $(basename "$bin") to /system/bin/hw"
        cp -f "$bin" "$ROOT/system/bin/hw/"
        chmod 0755 "$ROOT/system/bin/hw/$(basename "$bin")"
    done
fi
