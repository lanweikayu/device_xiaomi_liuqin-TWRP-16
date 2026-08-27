#!/bin/sh
# Device-tree post-install for liuqin recovery ramdisk.
# Args: TARGET_RECOVERY_ROOT_OUT  DEVICE_PREBUILT_DIR  DEPMOD
set -e

ROOT="$1"
PREBUILT="$2"
DEPMOD="$3"
TWRP_FONT="$PREBUILT/../../../../bootable/recovery/gui/theme/extra-languages/fonts/NotoSansCJKsc-Regular.ttf"

mkdir -p "$ROOT/vendor/lib/modules/1.1" "$ROOT/vendor/firmware" "$ROOT/twres/fonts" "$ROOT/twres/languages"
# Do not place modules in /lib/modules: that overlays vendor_boot and blacks
# the screen on `fastboot boot`. Early insmod is in init.recovery.qcom.rc.
rm -rf "$ROOT/lib/modules"

cp -f "$PREBUILT"/modules/*.ko "$ROOT/vendor/lib/modules/1.1/"
cp -f "$PREBUILT/modules.blocklist" "$ROOT/vendor/lib/modules/1.1/"
# Touch firmware lives outside /vendor so mounting a damaged vendor
# partition cannot hide it. Keep a ramdisk copy under /vendor/firmware too.
if [ -L "$ROOT/lib/firmware" ]; then rm -f "$ROOT/lib/firmware"; fi
if [ -L "$ROOT/system/etc/firmware" ]; then rm -f "$ROOT/system/etc/firmware"; fi
mkdir -p "$ROOT/lib/firmware" "$ROOT/system/etc/firmware" "$ROOT/vendor/firmware"
for fw in novatek_nt36532_m81_fw_csot.bin novatek_nt36532_m81_fw_tm.bin novatek_spi_fw.bin \
          novatek_nt36532_m81_mp_csot.bin novatek_nt36532_m81_mp_tm.bin; do
    if [ -f "$PREBUILT/firmware/$fw" ]; then
        cp -f "$PREBUILT/firmware/$fw" "$ROOT/lib/firmware/"
        cp -f "$PREBUILT/firmware/$fw" "$ROOT/system/etc/firmware/"
        cp -f "$PREBUILT/firmware/$fw" "$ROOT/vendor/firmware/"
    fi
done
# Kernel request_firmware default path is /lib/firmware (real files, not a
# symlink into /vendor). Do not create /lib/modules.

# TWRP userspace loader (vendor/lib/modules/1.1)
{
    echo "qcom_wdt_core.ko"
    echo "gh_virt_wdt.ko"
    echo "clk-rpmh.ko"
    echo "gcc-waipio.ko"
    echo "dispcc-waipio.ko"
    echo "pinctrl-cape.ko"
    echo "hwkm.ko"
    echo "tmecom-intf.ko"
    echo "crypto-qti-common.ko"
    echo "crypto-qti-hwkm.ko"
    echo "ufshcd-crypto-qti.ko"
    echo "phy-qcom-ufs.ko"
    echo "phy-qcom-ufs-qmp-v4-cape.ko"
    echo "qcom-reboot-reason.ko"
    echo "ufs_qcom.ko"
    echo "adsp_loader_dlkm.ko"
    echo "xiaomi_touch.ko"
    echo "nt36532_touch.ko"
    echo "msm_drm.ko"
    echo "qti_battery_charger_main_m81.ko"
} > "$ROOT/vendor/lib/modules/1.1/modules.load"

echo "calling depmod on recovery_prebuilt"
"$DEPMOD" -b "$ROOT/vendor" 1.1

if [ -f "$ROOT/system/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so" ]; then
    cp -f "$ROOT/system/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so" \
          "$ROOT/system/lib64/hw/android.hardware.boot@1.0-impl-1.2.so"
elif [ -f "$ROOT/vendor/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so" ]; then
    mkdir -p "$ROOT/system/lib64/hw"
    cp -f "$ROOT/vendor/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so" \
          "$ROOT/system/lib64/hw/android.hardware.boot@1.0-impl-1.2.so"
fi

# TWRP 16 prefers AIDL IBootControl if it is VINTF-declared. The AOSP
# default_recovery binary uses misc-based libboot_control, which does not
# switch Qualcomm GPT/UFS slots. Replace it with the QTI-backed service.
QTI_BOOT="$ROOT/system/bin/hw/android.hardware.boot-service.qti_recovery"
DEF_BOOT="$ROOT/system/bin/hw/android.hardware.boot-service.default_recovery"
if [ -f "$QTI_BOOT" ] && [ -f "$DEF_BOOT" ]; then
    cp -f "$QTI_BOOT" "$DEF_BOOT"
    chmod 0755 "$DEF_BOOT"
fi

# Device-type VINTF fragments must not sit in the framework manifest dir.
SYS_VINTF="$ROOT/system/etc/vintf/manifest"
VEN_VINTF="$ROOT/vendor/etc/vintf/manifest"
mkdir -p "$VEN_VINTF"
if [ -d "$SYS_VINTF" ]; then
    for f in "$SYS_VINTF"/*.xml; do
        [ -f "$f" ] || continue
        if grep -q 'type="device"' "$f"; then
            mv -f "$f" "$VEN_VINTF/"
        fi
    done
fi

# Crypto HALs must not exec from super /vendor: that pins vendor_a and Format
# Data cannot unmap it. Relink already drops them under ramdisk /vendor/bin;
# copy to /system/bin so init can start them even if something later mounts
# the vendor logical over /vendor.
mkdir -p "$ROOT/system/bin/hw"
if [ -f "$ROOT/vendor/bin/qseecomd" ]; then
    cp -f "$ROOT/vendor/bin/qseecomd" "$ROOT/system/bin/qseecomd"
    chmod 0755 "$ROOT/system/bin/qseecomd"
fi
if [ -d "$ROOT/vendor/bin/hw" ]; then
    for bin in "$ROOT/vendor/bin/hw"/*; do
        [ -f "$bin" ] || continue
        cp -f "$bin" "$ROOT/system/bin/hw/"
        chmod 0755 "$ROOT/system/bin/hw/$(basename "$bin")"
    done
fi

# Official extra-languages CJK fonts (recovery.img has no kernel, 100MiB is enough).
mkdir -p "$ROOT/twres/fonts"
if [ -f "$TWRP_FONT" ]; then
    cp -f "$TWRP_FONT" "$ROOT/twres/fonts/NotoSansCJKsc-Regular.ttf"
fi
JP_FONT="$PREBUILT/../../../../bootable/recovery/gui/theme/extra-languages/fonts/NotoSansCJKjp-Regular.ttf"
if [ -f "$JP_FONT" ]; then
    cp -f "$JP_FONT" "$ROOT/twres/fonts/NotoSansCJKjp-Regular.ttf"
fi
SINHALA_FONT="$PREBUILT/../../../../bootable/recovery/gui/theme/extra-languages/fonts/Sinhala.ttf"
if [ -f "$SINHALA_FONT" ] && [ ! -f "$ROOT/twres/fonts/Sinhala.ttf" ]; then
    cp -f "$SINHALA_FONT" "$ROOT/twres/fonts/Sinhala.ttf"
fi

rm -rf "$ROOT/system/etc/terminfo" "$ROOT/system/etc/nano" "$ROOT/system/etc/bash" \
      "$ROOT/system/usr/share/zoneinfo"
rm -f "$ROOT/system/bin/ttyd" \
      "$ROOT/system/bin/nano" \
      "$ROOT/system/bin/bash" \
      "$ROOT/system/bin/microhttpd" \
      "$ROOT/system/bin/lpdump" \
      "$ROOT/system/bin/lpdumpd" \
      "$ROOT/sbin/bash" \
      "$ROOT/system/lib64/libprotobuf-cpp-full.so" \
      "$ROOT/system/lib64/liblpdump.so" \
      "$ROOT/system/lib64/liblpdump_interface-cpp.so" \
      "$ROOT/system/lib64/liblpdump_interface-V1-cpp.so"
