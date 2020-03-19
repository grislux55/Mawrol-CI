#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in late_start service mode

chmod 755 $MODDIR/utils.sh
. $MODDIR/utils.sh

detect_os

while $(dumpsys window policy | grep mIsShowing | awk -F= '{print $2}'); do
sleep 1
done

if [ $os == "stock" ]; then
  resetprop ctl.stop oneplus_brain_service
  resetprop ctl.stop charger_logkit
  resetprop ctl.stop oemlogkit
  resetprop ctl.stop opdiagnose
  resetprop ctl.stop OPDiagdataCopy
  resetprop persist.sys.ohpd.flags 0
  resetprop persist.sys.ohpd.kcheck false
  resetprop persist.vendor.sys.memplus.enable 0
  log "[INFO]: 一加垃圾服务已停止"
fi

set_val /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq 2323200
set_val /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq 2649600
log "[INFO]: CPU频率限制已应用"

for i in /sys/block/*/queue; do
  set_val $i/nr_requests 128
  set_val $i/read_ahead_kb 128
done
log "[INFO]: 已将I/O状态设置为日常模式"

set_val /dev/blkio/blkio.group_idle 2000
set_val /dev/blkio/background/blkio.group_idle 0
set_val /dev/blkio/blkio.weight 1000
set_val /dev/blkio/background/blkio.weight 10
log "[INFO]: blkio限制参数已应用"

set_val /dev/stune/schedtune.prefer_idle 0
set_val /dev/stune/schedtune.boost 0
set_val /dev/stune/foreground/schedtune.prefer_idle 1
set_val /dev/stune/top-app/schedtune.prefer_idle 1
set_val /dev/stune/top-app/schedtune.boost 1
log "[INFO]: 日常stune参数已设置"

set_val /proc/sys/vm/dirty_background_ratio 10
set_val /proc/sys/vm/dirty_expire_centisecs 3000
set_val /proc/sys/vm/page-cluster 0
log "[INFO]: vm参数已设置"

stop vendor.msm_irqbalance
start vendor.msm_irqbalance
log "[INFO]: msm_irqbalance已重设"

for i in clkgate_enable hibern8_on_idle_enable; do
  if [ "$(cat /sys/devices/platform/soc/1d84000.ufshc/$i)" == "0" ]; then
    set_val /sys/devices/platform/soc/1d84000.ufshc/$i 1
    log "[INFO]: 已恢复关闭的UFS powersave $i"
  fi
done

if [ "$(cat /sys/module/lpm_levels/parameters/sleep_disabled)" == "Y" ]; then
  echo N > /sys/module/lpm_levels/parameters/sleep_disabled
  echo "[INFO]: 已恢复关闭的CPUidle lpm_level"
fi
