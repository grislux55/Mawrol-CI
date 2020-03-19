# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Mawrol kernel @ xda-developers
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=OnePlus7
device.name2=guacamoleb
device.name3=OnePlus7Pro
device.name4=guacamole
device.name5=OnePlus7ProTMO
device.name6=guacamolet
device.name7=OnePlus7T
device.name8=hotdogb
device.name9=OnePlus7TPro
device.name10=hotdog
device.name11=OnePlus7TProNR
device.name12=hotdogg
supported.versions=10
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot
is_slot_device=1
ramdisk_compression=auto

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;

# Detect device and system
hotdog="$(grep -wom 1 hotdog*.* /system/build.prop | sed 's/.....$//')";
guacamole="$(grep -wom 1 guacamole*.* /system/build.prop | sed 's/.....$//')";
userflavor="$(file_getprop /system/build.prop "ro.build.user"):$(file_getprop /system/build.prop "ro.build.flavor")";
userflavor2="$(file_getprop2 /system/build.prop "ro.build.user"):$(file_getprop2 /system/build.prop "ro.build.flavor")";
if [ "$userflavor" == "jenkins:$hotdog-user" ] || [ "$userflavor2" == "jenkins:$guacamole-user" ]; then
  os="stock";
  os_string="OxygenOS/HydrogenOS";
else
  os="custom";
  os_string="a custom ROM";
fi
ui_print " " "You are on $os_string!";

## AnyKernel install
dump_boot;

# Override DTB
ui_print " " "Overriding DTB...";
mv $home/dtb $home/split_img/

# Clean up existing ramdisk overlays
ui_print " " "Cleaning up existing ramdisk overlays...";
rm -rf $ramdisk/overlay;
rm -rf $ramdisk/overlay.d;

# Inject Magisk module
if [ -d $ramdisk/.backup ]; then
  ui_print " " "Magisk detected! Injecting Magisk module...";
  rm -rf /data/adb/modules/mawrol;
  mkdir -p /data/adb/modules/mawrol;
  cp -rfp $home/magisk/* /data/adb/modules/mawrol;
  chmod 755 /data/adb/modules/mawrol/*;
  chmod 644 /data/adb/modules/mawrol/module.prop;
  if [ $os == "stock" ]; then
    ui_print " " "Creating Oneplushit remover...";
    REPLACE="
/system/app/LogKitSdService
/system/app/OEMLogKit
/system/app/OPBugReportLite
/system/app/OPCommonLogTool
/system/app/OPIntelliService
/system/app/OPTelephonyDiagnoseManager
/system/priv-app/Houston
/system/priv-app/OPAppCategoryProvider
/system/priv-app/OPDeviceManager
/system/priv-app/OPDeviceManagerProvider
"
    OPCACHE="
system@app@LogKitSdService
system@app@OEMLogKit
system@app@OPBugReportLite
system@app@OPCommonLogTool
system@app@OPIntelliService
system@app@OPTelephonyDiagnoseManager
system@priv-app@Houston
system@priv-app@OPAppCategoryProvider
system@priv-app@OPDeviceManager
system@priv-app@OPDeviceManagerProvider
"
    OPDATA="
com.oem.logkitsdservice
com.oem.oemlogkit
com.oneplus.opbugreportlite
net.oneplus.opcommonlogtool
com.oneplus.asti
com.oneplus.diagnosemanager
com.oneplus.houston
net.oneplus.provider.appcategoryprovider
net.oneplus.odm.provider
net.oneplus.odm
"
    for TARGET in $REPLACE; do
      mkdir -p /data/adb/modules/mawrol/$TARGET;
      touch /data/adb/modules/mawrol/$TARGET/.replace;
    done
    for TARGET in $OPCACHE; do
      rm -f /data/dalvik-cache/arm64/$TARGET*;
    done
    for TARGET in $OPDATA; do
      rm -rf /data/data/$TARGET;
    done
  fi
fi

write_boot;
## end install
