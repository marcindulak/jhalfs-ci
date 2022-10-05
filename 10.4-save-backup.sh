#!/bin/bash
set -e

# Based on https://www.linuxfromscratch.org/lfs/view/systemd/chapter07/cleanup.html

if [ -z "$LFS" ]
then
    echo "Error: LFS must be defined"
    exit 1
fi

if [[ "$(pwd)" != "$LFS" ]];
then
    echo "Error: this script must be run from the 'LFS' directory"
    exit 1
fi

if [ -z "$1" ]
then
    echo "Error: backup name (e.g. chapter5) must be supplied"
    exit 1
fi

BACKUP_NAME=$1

mountpoint -q $LFS/dev/shm && umount -v $LFS/dev/shm
mountpoint -q $LFS/dev/pts && umount -v $LFS/dev/pts
for mp in sys proc run dev;
do
    mountpoint -q $LFS/$mp && umount -v $LFS/$mp
done

TARNAME=$BACKUP_NAME-$(date +%Y-%m-%d-T-%Hh%M).tar
tar --exclude ./jhalfs -cvf jhalfs/$TARNAME .
