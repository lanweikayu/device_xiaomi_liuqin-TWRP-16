#!/bin/sh
#
# Gate for prebuilt/replace_boot_hal.sh (run by CI before the ~2 h build).
#
# The hook runs at BOARD_RECOVERY_IMAGE_PREPARE time, i.e. after a full
# recovery build, so a mistake in it costs an entire build cycle to discover.
# This exercises it against a fake recovery root instead: it asserts what the
# script promises (QTI boot HAL installed under the name TWRP's rc expects,
# AOSP type="device" vintf fragment moved out of the framework manifest dir,
# 7za unzip wrapper installed, rotation set) without needing a device.
#
# Usage: sh prebuilt/test_replace_boot_hal.sh [path/to/replace_boot_hal.sh]
#
set -u

SCRIPT="${1:-$(dirname "$0")/replace_boot_hal.sh}"
[ -f "$SCRIPT" ] || { echo "test: no such script: $SCRIPT" >&2; exit 2; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/liuqin-boothal-XXXXXX")" || exit 2
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()  { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# mkroot <case-dir> [withdef]
# Materialises what the real build leaves in $TARGET_RECOVERY_ROOT_OUT at
# BOARD_RECOVERY_IMAGE_PREPARE time, at the real depth
# (<case>/out/target/product/liuqin/recovery) so the hook's
# $ROOT/../../system lookups resolve inside the case dir.
# Sets: R (recovery root), OUT (product dir), LOG (case log)
mkroot() {
    CASE="$1"
    R="$CASE/out/target/product/liuqin/recovery"
    OUT="$CASE/out/target/product/liuqin"
    LOG="$CASE/hook.log"
    BOOT_RC="$R/system/etc/init/android.hardware.boot-service.default_recovery.rc"
    rm -rf "$CASE"
    mkdir -p "$R/system/bin/hw" "$R/system/etc/vintf/manifest" "$R/system/etc/init" \
             "$R/system/lib64/hw" "$R/vendor/bin/hw" "$R/vendor/etc/vintf/manifest" \
             "$R/vendor/lib/modules/1.1"
    printf '#!/bin/sh\necho QTI\n' > "$R/system/bin/hw/android.hardware.boot-service.qti_recovery"
    if [ "${2:-}" = "withdef" ]; then
        printf '#!/bin/sh\necho AOSP\n' > "$R/system/bin/hw/android.hardware.boot-service.default_recovery"
    fi
    printf '#!/bin/sh\n' > "$R/system/bin/label_bootctrl.sh"
    printf '#!/bin/sh\n' > "$R/system/bin/unzip7za"
    printf '#!/bin/sh\n' > "$R/system/bin/7za"
    printf '#!/bin/sh\n' > "$R/system/bin/unzip"
    printf '#!/bin/sh\n' > "$R/vendor/bin/qseecomd"
    printf '#!/bin/sh\n' > "$R/vendor/bin/hw/android.hardware.keymaster@4.1-service-qti"
    printf 'resetprop persist.twrp.rotation 90\n' > "$R/init.recovery.qcom.rc"
    printf '<manifest type="device"/>\n' > "$R/system/etc/vintf/manifest/android.hardware.boot-service.default.xml"
    printf '<manifest type="device"/>\n' > "$R/system/etc/init/android.hardware.boot-service.default.rc"
    # rebuilt system image staged next to the recovery root
    mkdir -p "$OUT/system/bin" "$OUT/system/lib64"
    printf '#!/bin/sh\n' > "$OUT/system/bin/keystore2"
    printf 'ELF\n' > "$OUT/system/lib64/libminuitwrp.so"
}
run_hook() { sh "$SCRIPT" "$R" "${1:-}" > "$LOG" 2>&1; }
rc_of() { grep -o "persist.twrp.rotation [0-9]*" "$R/init.recovery.qcom.rc" 2>/dev/null; }

echo "== case 1: AOSP default_recovery not installed (Soong module is not in PRODUCT_PACKAGES)"
mkroot "$TMP/c1"
if run_hook; then ok "hook succeeds"; else bad "hook exits non-zero: $(tr '\n' ' ' < "$LOG")"; fi
if grep -q QTI "$R/system/bin/hw/android.hardware.boot-service.default_recovery" 2>/dev/null; then
    ok "default_recovery materialised from the QTI service"
else
    bad "default_recovery missing or not the QTI implementation"
fi
[ -f "$R/system/etc/init/android.hardware.boot-service.default.rc" ] \
    && bad "AOSP unprefixed boot HAL rc still present (would race IBootControl/default)" \
    || ok "AOSP unprefixed boot HAL rc removed"
[ -f "$BOOT_RC" ] && ok "enforcing boot HAL rc installed" || bad "boot HAL rc not installed"
grep -q 'IBootControl/default' "$BOOT_RC" 2>/dev/null \
    && ok "rc declares android.hardware.boot.IBootControl/default" || bad "rc does not declare IBootControl/default"
grep -q 'hal_bootctl_default' "$BOOT_RC" 2>/dev/null \
    && ok "rc keeps the hal_bootctl_default seclabel" || bad "rc lost its seclabel"
[ -f "$R/vendor/etc/vintf/manifest/android.hardware.boot-service.default.xml" ] \
    && ok 'type="device" vintf fragment moved to /vendor/etc/vintf' || bad "vintf fragment not moved"
[ -f "$R/system/etc/vintf/manifest/android.hardware.boot-service.default.xml" ] \
    && bad "vintf fragment left in the framework manifest dir" || ok "framework manifest dir cleaned"
cmp -s "$R/system/bin/unzip" "$R/system/bin/unzip7za" \
    && ok "unzip replaced by the 7za wrapper" || bad "unzip wrapper not installed"
[ "$(rc_of)" = "persist.twrp.rotation 90" ] && ok "landscape rotation 90" || bad "landscape rotation: $(rc_of)"
[ -f "$R/system/bin/keystore2" ] && ok "rebuilt keystore2 staged into the ramdisk" || bad "keystore2 not staged"
[ -f "$R/system/lib64/libminuitwrp.so" ] && ok "rebuilt libminuitwrp staged" || bad "libminuitwrp not staged"
[ -f "$R/system/bin/hw/android.hardware.keymaster@4.1-service-qti" ] \
    && ok "vendor/hw HALs copied to /system/bin/hw" || bad "vendor/hw HALs not copied"

echo "== case 2: AOSP default_recovery present (must still end up QTI-backed)"
mkroot "$TMP/c2" withdef
if run_hook; then ok "hook succeeds"; else bad "hook exits non-zero: $(tr '\n' ' ' < "$LOG")"; fi
grep -q QTI "$R/system/bin/hw/android.hardware.boot-service.default_recovery" \
    && ok "AOSP default replaced by the QTI implementation" || bad "AOSP default not replaced"

echo "== case 3: portrait sets rotation 0"
mkroot "$TMP/c3"
run_hook true
[ "$(rc_of)" = "persist.twrp.rotation 0" ] && ok "portrait rotation 0" || bad "portrait rotation: $(rc_of)"

echo "== case 4: missing QTI service must fail loudly"
mkroot "$TMP/c4"
rm -f "$R/system/bin/hw/android.hardware.boot-service.qti_recovery"
if run_hook; then
    bad "hook succeeded without the QTI service"
else
    grep -q 'missing QTI AIDL boot HAL' "$LOG" && ok "fails with a QTI message" || bad "unclear failure: $(cat "$LOG")"
fi

echo "== case 5: missing unzip7za wrapper must fail loudly"
mkroot "$TMP/c5"
rm -f "$R/system/bin/unzip7za"
if run_hook; then
    bad "hook succeeded without unzip7za"
else
    grep -q 'missing unzip7za' "$LOG" && ok "fails with an unzip7za message" || bad "unclear failure: $(cat "$LOG")"
fi

echo
echo "test_replace_boot_hal: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
echo "device tree pack hook OK"
