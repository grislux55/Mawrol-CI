#!/bin/bash

ANYKERNEL_PATH=./toolchain/anykernel

if [[ "${1}" != "skip" ]] ; then
	./build_clean.sh
fi

./build_kernel.sh "$@" || exit 1

VERSION="$(cat version)"

if [ -e arch/arm64/boot/Image.gz ] ; then
	echo "Packing Kernel Pkg"

	[ -f Mawrol-kernel-$VERSION.zip ] && echo "Removing Exist Pkg"
	[ -f Mawrol-kernel-$VERSION.zip ] && rm Mawrol-kernel-$VERSION.zip 2>/dev/null

	# Pack AnyKernel3
	rm -rf kernelzip
	mkdir kernelzip
	cp -rp $ANYKERNEL_PATH/* kernelzip/
	find arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > kernelzip/dtb
	cd kernelzip/
	7z a -mx9 Mawrol-kernel-$VERSION-tmp.zip *
	7z a -mx0 Mawrol-kernel-$VERSION-tmp.zip ../arch/arm64/boot/Image.gz
	zipalign -v 4 Mawrol-kernel-$VERSION-tmp.zip ../Mawrol-kernel-$VERSION.zip
	rm Mawrol-kernel-$VERSION-tmp.zip
	cd ..
	ls -al Mawrol-kernel-$VERSION.zip
fi

