# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
eval $(cat /tmp/anykernel/props | grep -v '\.')

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;

## AnyKernel install
dump_boot;

if [ ! -e /tmp/anykernel/Image.gz-dtb ]; then
  # Change skip_initramfs to want_initramfs if Magisk is detected
  IMAGE=/tmp/anykernel/Image;
  if [ ! -e $IMAGE ]; then
    gzip -dc < ${IMAGE}.gz > $IMAGE;
  fi
  if [ -d $ramdisk/.backup ]; then
    ui_print " ";
    ui_print "Magisk detected!";
    ui_print "Patching kernel so that reflashing Magisk is not necessary...";
    sed -i -e 's/skip_initramfs/want_initramfs/g' $IMAGE;
    gzip -9 < $IMAGE > ${IMAGE}.gz;
  fi

  if [ ! -e ${IMAGE}.gz ]; then
    gzip -9 < $IMAGE > ${IMAGE}.gz;
  fi

  cat ${IMAGE}.gz /tmp/anykernel/dtbs/*.dtb > /tmp/anykernel/Image.gz-dtb;
  rm $IMAGE ${IMAGE}.gz;
fi

# Install the boot image
write_boot;
