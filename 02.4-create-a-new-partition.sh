#!/bin/bash
set -e

if [[ "$(basename $(pwd))" != "jhalfs" ]];
then
    echo "Error: this script must be run from the 'jhalfs' directory"
    exit 1
fi

if [ -z "$1" ]
then
    echo "Error: image size in GB must be provided, e.g. 10"
    exit 1
fi

IMAGE_SIZE=$1

for dev in $(losetup -n -l -O NAME -j /vagrant/build_dir.img); do echo "Detaching $dev" && losetup -d $dev; done
for dev in $(losetup -n -l -O NAME -j /build_dir.img); do echo "Detaching $dev" && sudo losetup -d $dev; done
rm -f /vagrant/build_dir.img
dd if=/dev/zero of=/vagrant/build_dir.img bs=1024M count=$IMAGE_SIZE
# /vagrant synced-folder cannot be used for loop devices, but docker allows for this
# losetup: /vagrant/build_dir.img: failed to set up loop device: No such file or directory
losetup -fP /vagrant/build_dir.img
losetup -n -l -O NAME -j /vagrant/build_dir.img > build_dir.dev
parted -s $(cat build_dir.dev) mklabel msdos
parted -s $(cat build_dir.dev) print free
parted -s -a optimal $(cat build_dir.dev) mkpart primary 0% 100%
parted -s $(cat build_dir.dev) set 1 boot on
parted -s $(cat build_dir.dev) print free
