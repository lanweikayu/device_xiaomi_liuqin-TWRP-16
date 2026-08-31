#!/system/bin/sh
# Map TWRP battery/temp to the same sysfs Android uses.
# Thermal zone indices are DT-order dependent; match by type= instead of zoneN.

DEST=/dev/twrp_cpu_temp
PSY=/sys/class/power_supply/battery

# TWRP latches tw_no_cpu_temp if this path is missing at SetDefaultValues().
[ -e "$DEST" ] || echo 35000 > "$DEST"

chmod_batt() {
	[ -d "$PSY" ] || return 0
	for f in capacity status temp present; do
		[ -e "$PSY/$f" ] && chmod 0644 "$PSY/$f" 2>/dev/null || true
	done
}

link_tz() {
	want="$1"
	for z in /sys/class/thermal/thermal_zone*; do
		[ -e "$z/type" ] || continue
		t=$(cat "$z/type" 2>/dev/null) || continue
		[ "$t" = "$want" ] || continue
		[ -e "$z/temp" ] || continue
		chmod 0644 "$z/temp" 2>/dev/null || true
		ln -sf "$z/temp" "$DEST"
		return 0
	done
	return 1
}

chmod_batt

# Android dumpsys battery temperature / Thermal HAL type=BATTERY, not cpuss-*.
# quiet_therm / backlight_therm are board NTCs (~skin) if charger TZ is late.
link_tz battery \
	|| link_tz quiet_therm \
	|| link_tz backlight_therm \
	|| link_tz cpu_therm \
	|| link_tz cpuss-0

if [ ! -L "$DEST" ]; then
	for p in \
		/sys/class/thermal/thermal_zone81/temp \
		/sys/class/thermal/thermal_zone74/temp \
		"$PSY/temp"
	do
		[ -e "$p" ] || continue
		chmod 0644 "$p" 2>/dev/null || true
		ln -sf "$p" "$DEST"
		break
	done
fi

exit 0
