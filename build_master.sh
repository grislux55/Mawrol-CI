#!/bin/bash

if [[ "${1}" != "skip" ]] ; then
	./build_clean.sh
	./build_kernel.sh stock "$@" || exit 1
fi

VERSION="$(cat version)-$(date +'%y%m%d%H%M' | sed s@-@@g)"

if [ -e boot.img ] ; then
	rm Mawrol-$VERSION.zip 2>/dev/null
	cp boot.img Mawrol-$VERSION.img

	# Pack AnyKernel2
	rm -rf kernelzip
	mkdir -p kernelzip/dtbs
	cp arch/arm64/boot/Image.gz kernelzip/
	find arch/arm64/boot -name '*.dtb' -exec cp {} kernelzip/dtbs/ \;
	echo "
kernel.string=Mawrol kernel $(cat version) @ xda-developers
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=OnePlus7
device.name2=OnePlus7Pro
device.name3=guacamoleb
device.name4=guacamole
block=/dev/block/bootdevice/by-name/boot
is_slot_device=1
ramdisk_compression=lz4-l
" > kernelzip/props
	cp -rp ./ak2/* kernelzip/
	cd kernelzip/
	7z a -mx0 Mawrol-$VERSION-tmp.zip *
	zipalign -v 4 Mawrol-$VERSION-tmp.zip ../Mawrol-$VERSION.zip
	rm Mawrol-$VERSION-tmp.zip
	cd ..
	ls -al Mawrol-$VERSION.zip
fi
