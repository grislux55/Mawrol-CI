#!/bin/bash

export KERNELDIR=`readlink -f .`

echo "kerneldir = $KERNELDIR"

if [[ "${1}" == "skip" ]] ; then
	echo "Skipping Compilation"
else
	echo "Compiling kernel"
	cp defconfig .config
	make "$@" || exit 1
fi

