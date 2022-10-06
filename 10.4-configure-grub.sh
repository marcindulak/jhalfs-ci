#!/bin/bash
set -e

if [[ "$(basename $(pwd))" != "vagrant" ]];
then
    echo "Error: this script must be run from the 'vagrant' directory"
    exit 1
fi

if [ -z "$LFS" ]
then
    echo "Error: LFS must be defined"
    exit 1
fi

# Umount virtual kernel filesystems
mountpoint -q $LFS/dev/shm && umount -v $LFS/dev/shm
mountpoint -q $LFS/dev/pts && umount -v $LFS/dev/pts
for mp in sys proc run dev;
do
    mountpoint -q $LFS/$mp && umount -v $LFS/$mp
done

# Mount virtual kernel filesystems
# https://www.linuxfromscratch.org/lfs/view/systemd/chapter07/kernfs.html
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

# Umount and mount the image file
mkdir -pv $LFS/vagrant
touch $LFS/vagrant/build_dir.img
mountpoint -q $LFS/vagrant/build_dir.img && umount -v $LFS/vagrant/build_dir.img
mount -v --bind $PWD/build_dir.img $LFS/vagrant/build_dir.img

# Enter chroot
# https://www.linuxfromscratch.org/lfs/view/systemd/chapter07/chroot.html
chroot $LFS /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login << 'EOCHROOT'

# Install grub onto the loopback block device
# https://www.linuxfromscratch.org/lfs/view/systemd/chapter10/grub.html
grub-install --target i386-pc $(losetup -n -l -O NAME -j /vagrant/build_dir.img)

# set root password
# https://unix.stackexchange.com/questions/306903/usermod-to-change-user-password-is-not-working
usermod --password $(openssl passwd -1 root) root

# Create grub.conf
# See the original one at https://www.linuxfromscratch.org/lfs/view/systemd/chapter10/grub.html
VMLINUZ_VERSION=$(echo /boot/vmlinuz* | cut -d- -f2-)
cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod ext2
set root=(hd0,msdos1)

menuentry "GNU/Linux, Linux ${VMLINUZ_VERSION}" {
        linux   /boot/vmlinuz-${VMLINUZ_VERSION} root=/dev/vda1 rw rootdelay=10
}
EOF

EOCHROOT
