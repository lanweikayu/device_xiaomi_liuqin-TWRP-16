#!/system/bin/sh
# Mount persist once at /persist (TWRP), then bind it to /mnt/vendor/persist (QSEE).
# Mounting the same block device at two paths makes TWRP report persist (and then data) as failed.

DEV=/dev/block/bootdevice/by-name/persist

mkdir -p /persist /mnt/vendor/persist

already() {
	grep -q " $1 " /proc/mounts
}

if already /persist; then
	already /mnt/vendor/persist || mount -o bind /persist /mnt/vendor/persist
	exit 0
fi

if already /mnt/vendor/persist; then
	already /persist || mount -o bind /mnt/vendor/persist /persist
	exit 0
fi

i=0
while [ "$i" -lt 25 ]; do
	[ -e "$DEV" ] && break
	sleep 0.2
	i=$((i + 1))
done

if [ ! -e "$DEV" ]; then
	echo "bind_persist: $DEV missing" >&2
	exit 1
fi

mount -t ext4 -o noatime,nosuid,nodev "$DEV" /persist || exit 1
mount -o bind /persist /mnt/vendor/persist || exit 1
mkdir -p /mnt/vendor/persist/data
exit 0
