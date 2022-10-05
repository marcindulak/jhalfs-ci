#!/bin/bash
set -e

if [[ "$(basename $(pwd))" != "jhalfs" ]];
then
    echo "Error: this script must be run from the 'jhalfs' directory"
    exit 1
fi

source jhalfs.sh

yes | mkfs -v -t ext4 $(cat build_dir.dev)p1
mkdir $LFS
mount -v -t ext4 $(cat build_dir.dev)p1 $LFS
echo $(cat build_dir.dev)p1 $LFS ext4 defaults 1 1 >> /etc/fstab
umount $LFS
mount -v -a | grep $LFS
