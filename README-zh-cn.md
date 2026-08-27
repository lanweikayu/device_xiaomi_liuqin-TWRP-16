# 小米平板 6 Pro（liuqin）的 TWRP 设备树

[English](README.md)

适用于小米平板 6 Pro、项目代号 `liuqin`（型号 `23046RP50C`）的 TWRP 16

维护者：`兰微卡鱼`

## 参考项目

本设备树对照 TWRP 12.1 参考树 改写：

- [device_xiaomi_liuqin-TWRP](https://github.com/ymdzq/device_xiaomi_liuqin-TWRP)（TWRP 12.1，`portrait_hdpi`）

## 自行构建

### 环境要求

- 64 位 Linux 构建环境
- Git 和 Android `repo` 工具
- 编译 AOSP 所需的常规依赖包（本机构建使用 OpenJDK 17）
- 足够存放 Android 16 源码及编译输出的磁盘空间

### 同步源码

新建工作目录并同步未经修改的 TWRP-Test Android 16 官方源码：

```shell
mkdir -p twrp16
cd twrp16
repo init --depth=1 -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git -b twrp-16.0
repo sync
```

不要将 `bootable/recovery` 替换为设备专用 fork

### 添加设备树

将本仓库克隆或复制到 TWRP 源码中的以下准确路径：

```text
device/xiaomi/liuqin
```

从远程仓库克隆时可使用：

```shell
mkdir -p device/xiaomi
git clone https://github.com/lanweikayu/device_xiaomi_liuqin-TWRP-16.git device/xiaomi/liuqin
```

完成后应能找到以下产品配置文件：

```text
device/xiaomi/liuqin/AndroidProducts.mk
device/xiaomi/liuqin/twrp_liuqin.mk
```

### 准备编译环境

在已同步的 TWRP 源码根目录中执行：

```shell
export ALLOW_MISSING_DEPENDENCIES=true
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
source build/envsetup.sh
lunch twrp_liuqin-bp2a-eng
```
### 构建横屏版

```shell
unset USE_PORTRAIT
lunch twrp_liuqin-bp2a-eng
mka installclean
mka recoveryimage
```

### 构建竖屏版

```shell
export USE_PORTRAIT=true
lunch twrp_liuqin-bp2a-eng
mka installclean
mka recoveryimage USE_PORTRAIT=true
```

成功的编译会以 `build completed successfully` 结束
生成的镜像位于：

```text
out/target/product/liuqin/recovery.img
```

## 功能状态

本机已验证：

- [X] ADB
- [X] 数据解密
- [X] 屏幕显示
- [X] 分区挂载
- [X] 触控
- [X] Fastbootd
- [X] USB OTG
- [X] 备份和恢复
- [X] 镜像刷入

## Bug 修复

- 现在可以正常解压 ZIP64 归档中单个大于 4 GB 的条目（`unzip -p`）。原版
  `unzip`（`system/libziparchive` 提供的 ziptool）会先把整个未压缩条目分配
  到内存再写回 stdout，内存不足时触发 `bad_alloc`/OOM，导致输出截断。设备树
  通过 `BOARD_RECOVERY_IMAGE_PREPARE` 安装了基于 `7za` 的 `unzip` 包装脚本，
  以流式方式解压 ZIP64 条目，`unzip -p package.zip images/super.img.zst`
  可以输出完整内容且退出码可靠。

## 已知约束
- 进入 TWRP 界面需要当前槽位的 `boot` + `vendor_boot` + `recovery``dtbo`
- 解密 `/data` 还需要 `persist`（QSEE 密钥）和 `metadata`

## 设备信息

- 产品：Xiaomi Pad 6 Pro / `23046RP50C` / `liuqin`（vendor SKU `cape`）
- 平台：Qualcomm `taro` / SM8475（骁龙 8+ Gen 1），Adreno 730
- 内核：arm64，`5.10` GKI，4 KiB 页大小
- Boot 头：v4
- 屏幕：单 DSI，原生竖屏 1800×2880 @ 120/144 Hz，360 dpi，亮度最大 4095
- 触控：`nt36532_touch.ko` + `xiaomi_touch.ko`，固件 `novatek_nt36532_m81_fw_{csot,tm}.bin`
- 加密：FBE `file` + `wrappedkey_v0` + metadata；userdata 为 f2fs
- 分区：A/B + Virtual A/B，独立 `recovery_a` / `recovery_b`
- Recovery 分区大小：104857600 字节（100 MiB）
- 动态分区：ext4 / erofs 双 fstab；super 约 8.5 GiB
- 无独立 SD 卡槽；USB 控制器 `a600000.dwc3`

## 刷入方法

1. 从 Android 或可正常工作的 Recovery 进入 bootloader：

```shell
adb reboot bootloader
```

2. 确认电脑识别设备：

```shell
fastboot devices
```

3. 选择镜像并刷入两个 Recovery 槽位：

```shell
fastboot flash recovery_a "$RECOVERY_IMAGE"
fastboot flash recovery_b "$RECOVERY_IMAGE"
fastboot reboot recovery
```

不要使用：

```shell
fastboot boot recovery.img
```

无内核的 recovery 不能这样启动

## 致谢

- [device_xiaomi_liuqin-TWRP](https://github.com/ymdzq/device_xiaomi_liuqin-TWRP) — TWRP 12.1 参考设备树
- [TWRP-Test](https://github.com/TWRP-Test/platform_manifest_twrp_aosp)
- [TWRP](https://twrp.me/)
