# TWRP device tree for Xiaomi Pad 6 Pro (`liuqin`)

[简体中文](README-zh-cn.md)

TWRP 16 for Xiaomi Pad 6 Pro, codename `liuqin` (model `23046RP50C`).

Maintainer: `lanweikayu`

## References

This tree is adapted from the TWRP 12.1 reference tree:

- [device_xiaomi_liuqin-TWRP](https://github.com/ymdzq/device_xiaomi_liuqin-TWRP) (TWRP 12.1, `portrait_hdpi`)

## Building

### Requirements

- 64-bit Linux build host
- Git and the Android `repo` tool
- Usual AOSP build packages (this machine uses OpenJDK 17)
- Enough disk space for the Android 16 tree and build output

### Sync the sources

Create a working directory and sync unmodified TWRP-Test Android 16 sources:

```shell
mkdir -p twrp16
cd twrp16
repo init --depth=1 -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git -b twrp-16.0
repo sync
```

Do not replace `bootable/recovery` with a device-specific fork.

### Add the device tree

Clone or copy this repository to this exact path in the TWRP sources:

```text
device/xiaomi/liuqin
```

From a remote:

```shell
mkdir -p device/xiaomi
git clone https://github.com/lanweikayu/device_xiaomi_liuqin-TWRP-16.git device/xiaomi/liuqin
```

You should then have:

```text
device/xiaomi/liuqin/AndroidProducts.mk
device/xiaomi/liuqin/twrp_liuqin.mk
```

### Prepare the environment

From the synced TWRP source root:

```shell
export ALLOW_MISSING_DEPENDENCIES=true
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
source build/envsetup.sh
lunch twrp_liuqin-bp2a-eng
```

### Landscape build

```shell
unset USE_PORTRAIT
lunch twrp_liuqin-bp2a-eng
mka installclean
mka recoveryimage
```

### Portrait build

```shell
export USE_PORTRAIT=true
lunch twrp_liuqin-bp2a-eng
mka installclean
mka recoveryimage USE_PORTRAIT=true
```

A successful build ends with `build completed successfully`.
The image is at:

```text
out/target/product/liuqin/recovery.img
```

## Feature status

Verified on device:

- [X] ADB
- [X] Data decrypt
- [X] Display
- [X] Partition mount
- [X] Touch
- [X] Fastbootd
- [X] USB OTG
- [X] Backup and restore
- [X] Image flashing

## Known constraints

- The TWRP UI needs the current slot's `boot` + `vendor_boot` + `recovery` + `dtbo`
- Decrypting `/data` also needs `persist` (QSEE keys) and `metadata`

## Device info

- Product: Xiaomi Pad 6 Pro / `23046RP50C` / `liuqin` (vendor SKU `cape`)
- Platform: Qualcomm `taro` / SM8475 (Snapdragon 8+ Gen 1), Adreno 730
- Kernel: arm64, `5.10` GKI, 4 KiB pages
- Boot header: v4
- Display: single DSI, native portrait 1800×2880 @ 120/144 Hz, 360 dpi, brightness max 4095
- Touch: `nt36532_touch.ko` + `xiaomi_touch.ko`, firmware `novatek_nt36532_m81_fw_{csot,tm}.bin`
- Encryption: FBE `file` + `wrappedkey_v0` + metadata; userdata is f2fs
- Partitions: A/B + Virtual A/B, dedicated `recovery_a` / `recovery_b`
- Recovery partition size: 104857600 bytes (100 MiB)
- Dynamic partitions: dual ext4 / erofs fstab; super about 8.5 GiB
- No microSD slot; USB controller `a600000.dwc3`

## Flashing

1. Reboot to the bootloader from Android or a working recovery:

```shell
adb reboot bootloader
```

2. Confirm the computer sees the device:

```shell
fastboot devices
```

3. Flash both recovery slots:

```shell
fastboot flash recovery_a "$RECOVERY_IMAGE"
fastboot flash recovery_b "$RECOVERY_IMAGE"
fastboot reboot recovery
```

Do not use:

```shell
fastboot boot recovery.img
```

A kernel-less recovery cannot be started that way.

## Credits

- [device_xiaomi_liuqin-TWRP](https://github.com/ymdzq/device_xiaomi_liuqin-TWRP) — TWRP 12.1 reference tree
- [TWRP-Test](https://github.com/TWRP-Test/platform_manifest_twrp_aosp)
- [TWRP](https://twrp.me/)
