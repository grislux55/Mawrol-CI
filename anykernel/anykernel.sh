# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

# set up working directory variables
test "$home" || home=$PWD;
bootimg=$home/boot.img;
bin=$home/tools;
patch=$home/patch;
ramdisk=$home/ramdisk;
split_img=$home/split_img;

## AnyKernel setup
eval $(cat $home/props | grep -v '\.')

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel install
dump_boot;

# Use the provided dtb
mv $home/dtb $home/split_img/;

# Change skip_initramfs to want_initramfs if Magisk is detected
if [ -e /sbin/pigz ]; then
  GZIP="pigz -p4";
else
  GZIP="gzip";
fi
if [ -d $ramdisk/.backup ]; then
  ui_print " ";
  ui_print "Magisk detected!";
  ui_print "Patching kernel so that reflashing Magisk is not necessary...";
  $GZIP -dc < $home/Image.gz | sed -e 's/skip_initramfs/want_initramfs/g' | $GZIP > $home/Image.gz.tmp;
  mv $home/Image.gz.tmp $home/Image.gz;
fi

# Install the boot image
write_boot;

## end install
