#!/bin/bash
export KERNELDIR=`readlink -f .`

echo "kerneldir = $KERNELDIR"

if [[ "${1}" == "skip" ]] ; then
	echo "Skipping Compilation"
else
	sed -i -e 's@"want_initramfs"@"skip_initramfs"@g' init/initramfs.c
	echo "Compiling kernel"
	cp defconfig .config
	make "$@" || exit 1
	sed -i -e 's@"skip_initramfs"@"want_initramfs"@g' init/initramfs.c
fi
