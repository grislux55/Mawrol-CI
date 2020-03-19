#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode

if ! grep -q Mawrol /proc/version; then
  touch $MODDIR/remove
  exit 0
fi

chmod 755 $MODDIR/utils.sh
. $MODDIR/utils.sh

rm -f $MODDIR/log

detect_os

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

if [ $os == "stock" ]; then
  feature_list="
OP_FEATURE_AI_BOOST_PACKAGE
OP_FEATURE_APP_PRELOAD
OP_FEATURE_BUGREPORT
OP_FEATURE_OHPD
OP_FEATURE_OPDIAGNOSE
OP_FEATURE_PRELOAD_APP_TO_DATA
OP_FEATURE_SMART_BOOST
"
  mkdir -p $MODDIR/system/etc/
  cp -f /system/etc/feature_list $MODDIR/system/etc/feature_list
  for i in $feature_list ; do
    if [ "$(grep $i $MODDIR/system/etc/feature_list)" != "" ]; then
      sed -i -e "/$i/{n;d}" -e "$!N;/\n.*$i/!P;D" $MODDIR/system/etc/feature_list
      sed -i "/$i/d" $MODDIR/system/etc/feature_list
    fi
  done
  log "[INFO]: feature_list修改完毕"

  mkdir -p $MODDIR/system/vendor/etc/init/hw/
  cp -f /system/vendor/etc/init/hw/init.oem.rc $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  cp -f /system/vendor/etc/init/hw/init.qcom.rc $MODDIR/system/vendor/etc/init/hw/init.qcom.rc
  cp -f /system/vendor/etc/init/hw/init.oem.debug.rc $MODDIR/system/vendor/etc/init/hw/init.oem.debug.rc
  sed -i '/houston/d' $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  sed -i '/cc_ctl/d' $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  sed -i '/opchain/d' $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  sed -i '/ht_ctl/d' $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  sed -i '/core_ctl/d' $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  sed -i '/service bugreport/,/oneshot/d' $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  sed -i '/service OPDiagdataCopy/,/start OPDiagdataCopy/d' $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  sed -i '/service opdiagnose/,/group system/d' $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  sed -i '/OPDiagnose/d' $MODDIR/system/vendor/etc/init/hw/init.oem.rc
  sed -i '/fragment_monitor/d' $MODDIR/system/vendor/etc/init/hw/init.qcom.rc
  sed -i '/service oemlogkit/,/socket oemlogkit/d' $MODDIR/system/vendor/etc/init/hw/init.oem.debug.rc
  sed -i '/service charger_logkit/,/seclabel u:r:charger_log:s0/d' $MODDIR/system/vendor/etc/init/hw/init.oem.debug.rc
  log "[INFO]: 一加垃圾启动项删减完毕"
fi
