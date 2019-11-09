#!/bin/bash

if [[ "${1}" != "skip" ]] ; then
	./build_clean.sh
	./build_kernel.sh stock "$@" || exit 1
fi

VERSION="$(cat version)-$(date +'%y%m%d%H%M' | sed s@-@@g)"

if [ -e boot.img ] ; then
	rm Mawrol-$VERSION.zip 2>/dev/null
	cp boot.img Mawrol-$VERSION.img

	# Pack AnyKernel3
	rm -rf kernelzip
	mkdir kernelzip
	echo "
kernel.string=Mawrol kernel $(cat version) @ xda-developers
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=OnePlus7
device.name2=OnePlus7Pro
device.name3=OnePlus7T
device.name4=OnePlus7TPro
device.name5=guacamoleb
device.name6=guacamole
device.name7=hotdogb
device.name8=hotdog
block=/dev/block/bootdevice/by-name/boot
is_slot_device=1
ramdisk_compression=gzip
" > kernelzip/props
	cp -rp ./anykernel/* kernelzip/
	find arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > kernelzip/dtb
	cd kernelzip/
	7z a -mx9 Mawrol-$VERSION-tmp.zip *
	7z a -mx0 Mawrol-$VERSION-tmp.zip ../arch/arm64/boot/Image.gz
	zipalign -v 4 Mawrol-$VERSION-tmp.zip ../Mawrol-$VERSION.zip
	rm Mawrol-$VERSION-tmp.zip
	cd ..
	ls -al Mawrol-$VERSION.zip
fi
