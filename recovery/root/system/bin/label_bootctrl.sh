#!/system/bin/sh
# Relabel nodes the QTI boot HAL needs. AOSP neverallow forbids
# hal_bootctl_default from open/rw on generic block_device / device.
for n in /dev/ufs-bsg /dev/ufs-bsg0; do
    if [ -e "$n" ]; then
        chcon u:object_r:ufs_bsg_device:s0 "$n" || true
        chmod 0666 "$n" || true
    fi
done
for n in /dev/block/sd[a-z]; do
    if [ -e "$n" ]; then
        chcon u:object_r:ufs_lun_block_device:s0 "$n" || true
    fi
done
