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

if mountpoint $LFS/dev/shm; then umount -v $LFS/dev/shm; fi
if mountpoint $LFS/dev/pts; then umount -v $LFS/dev/pts; fi
for mp in sys proc run dev;
do
    if mountpoint $LFS/$mp; then umount -v $LFS/$mp; fi
done

TARNAME=$BACKUP_NAME-$(date +%Y-%m-%d-T-%Hh%M).tar
tar --exclude ./jhalfs --exclude ./sources --exclude ./vagrant -cpvf jhalfs/$TARNAME .
