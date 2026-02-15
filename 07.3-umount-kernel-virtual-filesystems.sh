#!/bin/bash
set -e

if [ -z "$LFS" ]
then
    echo "Error: LFS must be defined"
    exit 1
fi

# See https://www.linuxfromscratch.org/lfs/view/systemd/chapter07/kernfs.html

# Umount virtual kernel filesystems
if mountpoint $LFS/dev/shm; then umount -v $LFS/dev/shm; fi
if mountpoint $LFS/dev/pts; then umount -v $LFS/dev/pts; fi
for mp in sys proc run dev;
do
    if mountpoint $LFS/$mp; then umount -v $LFS/$mp; fi
done
