#!/bin/bash

git clone https://github.com/kdrag0n/proton-clang ./toolchain/proton-clang --depth=1

jobs="-j$(nproc --all)"

cp -fp ./toolchain/misc/dtc /usr/bin
echo "Compiling! (Using $jobs flag)"
./build_master.sh "ci" $jobs || exit

