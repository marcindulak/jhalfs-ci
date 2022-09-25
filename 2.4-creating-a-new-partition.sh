#!/bin/bash
set -e

if [[ "$(basename $(pwd))" != "jhalfs" ]];
then
    echo "Error: this script must be run from the 'jhalfs' directory"
    exit 1
fi

for dev in $(losetup -n -l -O NAME -j /build_dir.img); do echo "Detaching $dev" && losetup -d $dev; done
rm -f /build_dir.img
# /vagrant synced-folder cannot be used for loop devices
# losetup: /vagrant/jhalfs/build_dir.img: failed to set up loop device: No such file or directory
dd if=/dev/zero of=/build_dir.img bs=1024M count=15
losetup -fP /build_dir.img
losetup -n -l -O NAME -j /build_dir.img > build_dir.dev
parted -s $(cat build_dir.dev) mklabel gpt
parted -s $(cat build_dir.dev) print free
parted -s -a optimal $(cat build_dir.dev) mkpart primary 0% 100%
parted -s $(cat build_dir.dev) print free
