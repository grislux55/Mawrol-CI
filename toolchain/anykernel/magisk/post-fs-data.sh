#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode

if ! grep -q pa-mod /proc/version; then
  touch $MODDIR/remove
  exit 0
fi

chmod 755 $MODDIR/utils.sh
. $MODDIR/utils.sh

rm -f $MODDIR/log

set_val /sys/devices/platform/soc/1d84000.ufshc/clkgate_enable 0
set_val /sys/devices/platform/soc/1d84000.ufshc/hibern8_on_idle_enable 0
log "[INFO]: 启动时UFS powersave已关闭"

set_val /sys/module/lpm_levels/parameters/sleep_disabled Y
log "[INFO]: 启动时CPUidle lpm_level已关闭"

set_val /dev/stune/schedtune.prefer_idle 1
set_val /dev/stune/schedtune.boost 100
log "[INFO]: 启动时stune参数已设置"

for i in /sys/block/*/queue; do
  set_val $i/iostats 0
  set_val $i/nr_requests 256
  set_val $i/read_ahead_kb 2048
done
log "[INFO]: 已将I/O状态设置为启动模式"
