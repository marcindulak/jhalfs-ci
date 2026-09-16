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

# See https://www.linuxfromscratch.org/lfs/view/systemd/chapter10/grub.html

# Remount kernel virtual filesystems before entering chroot
bash 07.3-remount-kernel-virtual-filesystems.sh

# Umount and mount the image file
mkdir -pv $LFS/vagrant
touch $LFS/vagrant/build_dir.img
if mountpoint $LFS/vagrant/build_dir.img; then umount -v $LFS/vagrant/build_dir.img; fi
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
