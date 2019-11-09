#!/bin/bash

jobs="-j$(nproc --all)"
commit="$(cut -c-12 <<< "$(git rev-parse HEAD)")"

cp -f ./build_tools/dtc /usr/bin
echo "Start compiling! (Using $jobs flag)"
./build_master.sh $jobs || exit

git config --global user.name $GITNAME
git config --global user.email $GITEMAIL

git clone https://$GITID:$GITPWD@github.com/grislux55/kernel_release
cd kernel_release
mkdir -p $commit
cp ../Mawrol-*.zip ./$commit

git add . && git commit -m "build for $commit" -s
git push https://$GITID:$GITPWD@github.com/grislux55/kernel_release HEAD:master

