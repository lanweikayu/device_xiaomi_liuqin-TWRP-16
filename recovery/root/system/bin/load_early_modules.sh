#!/system/bin/sh
# Load ramdisk modules before init waits on /dev/block (flashed recovery).
# Modules already loaded from vendor_boot are ignored.
#
# nt36532 starts Boot_Update_Firmware as delayed_work (~5s). Insmod it as
# soon as DRM/touch deps are up, and before the large ufs_qcom.ko, so that
# delay overlaps UFS/QSEE instead of blocking the TWRP UI.
MODDIR=/vendor/lib/modules/1.1
ins() {
  [ -f "$MODDIR/$1" ] || return 0
  /system/bin/insmod "$MODDIR/$1" >/dev/null 2>&1 || true
}

# Kernel request_firmware looks at /lib/firmware; enable sysfs fallback too.
echo 1 > /proc/sys/kernel/firmware_config/force_sysfs_fallback 2>/dev/null || true
if [ -e /sys/module/firmware_class/parameters/path ]; then
  echo -n /lib/firmware > /sys/module/firmware_class/parameters/path 2>/dev/null || true
fi

# Watchdog first.
ins qcom_wdt_core.ko
ins gh_virt_wdt.ko

# Display clocks / pinctrl (vendor_boot usually has these already).
ins qcom-scm.ko
ins smem.ko
ins minidump.ko
ins cmd-db.ko
ins qcom_ipc_logging.ko
ins qcom_rpmh.ko
ins clk-rpmh.ko
ins debug-regulator.ko
ins proxy-consumer.ko
ins gdsc-regulator.ko
ins clk-qcom.ko
ins gcc-waipio.ko
ins dispcc-waipio.ko
ins pinctrl-msm.ko
ins pinctrl-cape.ko

# DRM + Novatek deps, then touch — start the ~5s firmware work now.
ins panel_event_notifier.ko
ins miev.ko
ins qcom_smd.ko
ins qcom_glink.ko
ins qcom_glink_smem.ko
ins rproc_qcom_common.ko
ins qmi_helpers.ko
ins pdr_interface.ko
ins pmic_glink.ko
ins qti_battery_charger_main_m81.ko
ins pm8941-pwrkey.ko
ins msm_dma_iommu_mapping.ko
ins qcom_iommu_util.ko
ins llcc-qcom.ko
ins msm-mmrm.ko
ins spmi-pmic-arb.ko
ins gh_arm_drv.ko
ins gh_msgq.ko
ins gh_dbl.ko
ins gh_rm_drv.ko
ins secure_buffer.ko
ins mem_buf_dev.ko
ins qseecom-mod.ko
ins hdcp_qseecom.ko
ins ucsi_glink.ko
ins mmhardware_sysfs.ko
ins qti-regmap-debugfs.ko
ins fsa4480-i2c.ko
ins msm_ext_display.ko
ins altmode-glink.ko
ins redriver.ko
ins dwc3-msm.ko
ins gh_irq_lend.ko
ins gh_mem_notifier.ko
ins msm_drm.ko
ins xiaomi_touch.ko
ins qcom-cpufreq-hw.ko
ins mi_schedule.ko
ins metis.ko
ins sched-walt.ko
ins qcom_lpm.ko
ins nt36532_touch.ko

# Storage / ADSP after touch so ufs_qcom does not delay firmware start.
ins tmecom-intf.ko
ins hwkm.ko
ins crypto-qti-hwkm.ko
ins crypto-qti-common.ko
ins ufshcd-crypto-qti.ko
ins phy-qcom-ufs.ko
ins phy-qcom-ufs-qmp-v4-cape.ko
ins qcom-reboot-reason.ko
ins ufs_qcom.ko
ins snd_event_dlkm.ko
ins q6_pdr_dlkm.ko
ins q6_notifier_dlkm.ko
ins gpr_dlkm.ko
ins spf_core_dlkm.ko
ins adsp_loader_dlkm.ko
exit 0
