#!/bin/bash

export KERNELDIR=`readlink -f .`
export GCC64_PATH=./toolchain/aarch64-elf-gcc/bin/aarch64-elf-
export GCC32_PATH=./toolchain/arm-eabi-gcc/bin/arm-eabi-

echo "kerneldir = $KERNELDIR"

if [[ "${1}" == "skip" ]] ; then
	echo "Skipping Compilation"
else
	echo "Compiling kernel"
	cp defconfig .config
	make "$@" || exit 1
fi

