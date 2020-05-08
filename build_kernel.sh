#!/bin/bash
export KERNELDIR=`readlink -f .`

if [[ "${1}" == "ci" ]] ; then
	export CLANG_PATH=./toolchain/proton-clang/bin
else
	export CLANG_PATH=~/kernel/clang/proton-clang/bin
fi

export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=$CLANG_PATH/aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=$CLANG_PATH/arm-linux-gnueabi-
export PATH=${CLANG_PATH}:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export LD_LIBRARY_PATH=$CLANG_PATH/../lib:$LD_LIBRARY_PATH

echo "kerneldir = $KERNELDIR"

if [[ "${1}" == "skip" ]] ; then
	echo "Skipping Compilation"
else
	sed -i -e 's@"want_initramfs"@"skip_initramfs"@g' init/initramfs.c
	echo "Compiling kernel"
	./generator ramdisk/init.qcom.post_boot.sh init/execprog.h
	cp defconfig .config
	make CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j$(nproc --all) || exit 1
	sed -i -e 's@"skip_initramfs"@"want_initramfs"@g' init/initramfs.c
fi
