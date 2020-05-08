#!/bin/bash
export KERNELDIR=`readlink -f .`
export GCC64_PATH=./toolchain/proton-clang/bin/aarch64-linux-gnu-
export GCC32_PATH=./toolchain/proton-clang/bin/arm-linux-gnueabi-
export CLANG_PATH=./toolchain/proton-clang/bin/
export PATH=${CLANG_PATH}:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=./toolchain/proton-clang/bin/aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=./toolchain/proton-clang/bin/arm-linux-gnueabi-
export LD_LIBRARY_PATH=./toolchain/proton-clang/lib:$LD_LIBRARY_PATH

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
