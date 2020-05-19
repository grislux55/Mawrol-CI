#!/bin/bash
export KERNELDIR=`readlink -f .`
export GCC64_PATH=./toolchain/aarch64-linux-elf/bin/aarch64-linux-elf-
export GCC32_PATH=./toolchain/arm-linux-eabi/bin/arm-linux-eabi-

echo "kerneldir = $KERNELDIR"

if [[ "${1}" == "skip" ]] ; then
	echo "Skipping Compilation"
else
	sed -i -e 's@"want_initramfs"@"skip_initramfs"@g' init/initramfs.c
	echo "Compiling kernel"
	./generator ramdisk/init.qcom.post_boot.sh init/execprog.h
	cp defconfig .config
	make "$@" || exit 1
	sed -i -e 's@"skip_initramfs"@"want_initramfs"@g' init/initramfs.c
fi
