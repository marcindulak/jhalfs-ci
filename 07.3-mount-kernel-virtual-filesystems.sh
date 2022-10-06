#!/bin/bash
set -e

if [ -z "$LFS" ]
then
    echo "Error: LFS must be defined"
    exit 1
fi

# See https://www.linuxfromscratch.org/lfs/view/systemd/chapter07/kernfs.html

# Umount virtual kernel filesystems
mountpoint -q $LFS/dev/shm && umount -v $LFS/dev/shm
mountpoint -q $LFS/dev/pts && umount -v $LFS/dev/pts
for mp in sys proc run dev;
do
    mountpoint -q $LFS/$mp && umount -v $LFS/$mp
done

# Mount virtual kernel filesystems
mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
else
  mount -t tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi
