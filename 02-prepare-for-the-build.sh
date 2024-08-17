#!/bin/bash
set -e

if [[ "$(basename $(pwd))" != "vagrant" ]];
then
    echo "Error: this script must be run from the 'vagrant' directory"
    exit 1
fi

# /vagrant synced folder is used to share the files between the vagrant guest and laptop host
# The script assumes it is executed on the vagrant guest from under /vagrant

mkdir jhalfs
mkdir jhalfs/mnt
mkdir -p sources

# Define LFS directory
# See https://www.linuxfromscratch.org/lfs/view/systemd/chapter02/aboutlfs.html
echo export LFS=$PWD/jhalfs/mnt/build_dir > jhalfs/jhalfs.sh
# Export the variable used by jhalfs for storing the downloaded sources
# See https://www.linuxfromscratch.org/alfs/documentation.html 4.2. PRELIMINARY TASKS
echo export SRC_ARCHIVE=$PWD/sources >> jhalfs/jhalfs.sh
# Configure make to run in parallel.
# Note that these settings are not effective and are overwritten by the book XML.
# See https://www.linuxfromscratch.org/lfs/view/systemd/chapter04/aboutsbus.html
echo export MAKEFLAGS="-j$(nproc)" >> jhalfs/jhalfs.sh
echo export N_PARALLEL=$(nproc) >> jhalfs/jhalfs.sh

# Create vagrant user which will perform the jhalfs run
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y sudo curl
echo 
cat /etc/{group,passwd}
groupadd --non-unique --gid 1000 vagrant
# ubuntu started including ubuntu user/group with ids 1000, so rename ubuntu to vagrant
# https://bugs.launchpad.net/cloud-images/+bug/2064537
getent passwd 1000 && usermod -l vagrant ubuntu
getent passwd 1000 && usermod -d /home/vagrant -m vagrant
getent passwd 1000 || useradd --uid 1000 -s /bin/bash -g vagrant -m -k /dev/null vagrant
echo 
cat /etc/{group,passwd}
usermod --password vagrant vagrant
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# The remaining parts assumes it is executed from under /vagrant/jhalfs
cd jhalfs

# Create device and parition it to use for the /mnt/build_dir mount point
# See https://www.linuxfromscratch.org/lfs/view/development/chapter02/creatingpartition.html
DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils parted udev
bash /vagrant/02.4-create-a-new-partition.sh 10
# Create loopback partition block devices with mknod
# https://github.com/moby/moby/issues/27886#issuecomment-417074845
bash /vagrant/02.7-mknod-loopback-partition.sh
# Format and mount the partition
# See https://www.linuxfromscratch.org/lfs/view/development/chapter02/mounting.html
bash /vagrant/02.7-mount-the-new-partition.sh
# Install dependencies mentioned in jhalfs README 2. PREREQUISITIES
DEBIAN_FRONTEND=noninteractive apt-get install -y wget sudo libxml2 libxslt-dev docbook-xml docbook-xsl-nons
# Install jhalfs dependencies, undocumented in jhalfs
DEBIAN_FRONTEND=noninteractive apt-get install -y git make python3 gcc libxml2-utils xsltproc
# Install this setup (jhalfs-ci) dependencies
DEBIAN_FRONTEND=noninteractive apt-get install -y tree vim
# Clone jhalfs, the requests tend to fail
# fatal: unable to access 'https://git.linuxfromscratch.org/jhalfs.git/': Could not resolve host: git.linuxfromscratch.org
su - vagrant -c 'cd /home/vagrant && if test ! -d lhafs; then while ! $(curl -s --max-time 5 -L git.linuxfromscratch.org > /dev/null); do echo Trying to reach git.linuxfromscratch.org ...  && sleep 5; done && git clone https://git.linuxfromscratch.org/jhalfs.git jhalfs; fi'
# Copy jhalfs configuration, fstab and kernel-config
su - vagrant -c 'cp -pv /vagrant/configuration /home/vagrant/jhalfs'
# https://www.linuxfromscratch.org/lfs/view/systemd/chapter03/introduction.html
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && sudo mkdir -v $LFS/sources'
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && sudo chmod -v a+wt $LFS/sources'
# https://www.linuxfromscratch.org/lfs/view/systemd/chapter10/fstab.html
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cp -pv /vagrant/fstab $LFS/sources'
# https://www.linuxfromscratch.org/lfs/view/systemd/chapter10/kernel.html
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cp -pv /vagrant/kernel-config $LFS/sources'
# Install lfs host requirements, undocumented in jhalfs
# See https://www.linuxfromscratch.org/lfs/view/systemd/chapter02/hostreqs.html
DEBIAN_FRONTEND=noninteractive apt-get install -y bison coreutils diffutils findutils gawk g++ grep gzip m4 make patch perl python3 sed tar texinfo xz-utils
# Install extra tools needed for parsing jhalfs makefile BREAKPOINT output
# See https://lists.linuxfromscratch.org/sympa/arc/alfs-discuss/2022-10/msg00013.html
DEBIAN_FRONTEND=noninteractive apt-get install -y ack colorized-logs
# Install tools needed for qemu image conversion
DEBIAN_FRONTEND=noninteractive apt-get install -y qemu-utils
# Generate the jhalfs makefiles under $LFS
# Downloading of patches tends to fail, run the scripts a few times
# Resolving www.linuxfromscratch.org (www.linuxfromscratch.org)... failed: Temporary failure in name resolution.
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd /home/vagrant/jhalfs && while ! $(curl -s --max-time 5 -L www.linuxfromscratch.org > /dev/null); do echo Trying to reach www.linuxfromscratch.org ...  && sleep 5; done && yes yes | ./jhalfs run'
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && MISSING_FILES_DMP=$LFS/sources/MISSING_FILES.DMP && echo Try 1: $MISSING_FILES_DMP && cat $MISSING_FILES_DMP'
# Use invisible-island.net, since invisible-mirror.net tends to give "Connection timed out."
# See https://lists.linuxfromscratch.org/sympa/arc/lfs-support/2022-09/msg00045.html
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd $LFS/jhalfs && for file in $(grep invisible-mirror -rl . | xargs); do echo "sed -i \"s/invisible-mirror/invisible-island/\" $file" && sed -i "s/invisible-mirror/invisible-island/" $file; done'

# Example of performing book-source local modifications
if test -n "";
   then
       # Use specific package version
       su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd $LFS/jhalfs && for file in $(grep "expat-version \"2.6.0\"" -rl . | xargs); do echo "sed -i \"s/expat-version \"2.6.0/expat-version \"2.6.2/\" $file" && sed -i "s/expat-version \"2.6.0/expat-version \"2.6.2/" $file; done'
       su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd $LFS/jhalfs && for file in $(grep "expat-md5 \"bd169cb11f4b9bdfddadf9e88a5c4d4b\"" -rl . | xargs); do echo "sed -i \"s/expat-md5 \"bd169cb11f4b9bdfddadf9e88a5c4d4b/expat-md5 \"0cb75c8feb842c0794ba89666b762a2d/\" $file" && sed -i "s/expat-md5 \"bd169cb11f4b9bdfddadf9e88a5c4d4b/expat-md5 \"0cb75c8feb842c0794ba89666b762a2d/" $file; done'
       # Don't checkout trunk as this will fail due to git rejecting the above book-source local modifications
       su - vagrant -c 'sed -i "/git checkout trunk/,+4d" /home/vagrant/jhalfs/common/libs/func_book_parser'
fi

# Continue fetching packages following the above book-source local modifications
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd /home/vagrant/jhalfs && while ! $(curl -s --max-time 5 -L www.linuxfromscratch.org > /dev/null); do echo Trying to reach www.linuxfromscratch.org ...  && sleep 5; done && yes yes | ./jhalfs run'
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && MISSING_FILES_DMP=$LFS/sources/MISSING_FILES.DMP && echo Try 2: $MISSING_FILES_DMP && cat $MISSING_FILES_DMP'
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd /home/vagrant/jhalfs && while ! $(curl -s --max-time 5 -L www.linuxfromscratch.org > /dev/null); do echo Trying to reach www.linuxfromscratch.org ...  && sleep 5; done && yes yes | ./jhalfs run'
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && MISSING_FILES_DMP=$LFS/sources/MISSING_FILES.DMP && echo Try 3: $MISSING_FILES_DMP && cat $MISSING_FILES_DMP'
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && MISSING_FILES_DMP=$LFS/sources/MISSING_FILES.DMP && test -z "$(cat $MISSING_FILES_DMP)" || (echo $MISSING_FILES_DMP is non empty && exit 1)'
# Extract the jhalfs make targets
source jhalfs.sh
grep $'all:\t' $LFS/jhalfs/Makefile | cut -d: -f 2- | xargs > targets

# Mark as done by creating a file
touch up
