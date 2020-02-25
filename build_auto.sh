#!/bin/bash

jobs="-j$(nproc --all)"

cp -fp ./toolchain/misc/dtc /usr/bin
echo "Compiling! (Using $jobs flag)"
./build_master.sh $jobs || exit

