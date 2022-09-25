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
# Configure make to run in parallel
# See https://www.linuxfromscratch.org/lfs/view/systemd/chapter04/aboutsbus.html
echo export MAKEFLAGS="-j$(nproc)" >> jhalfs/jhalfs.sh

# Create vagrant user which will perform the jhalfs run
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y sudo curl
groupadd --gid 1000 vagrant
useradd --uid 1000 -s /bin/bash -g vagrant -m -k /dev/null vagrant
usermod --password vagrant vagrant
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# The remaining parts assumes it is executed from under /vagrant/jhalfs
cd jhalfs

# Create device and parition it to use for the /mnt/build_dir mount point
# See https://www.linuxfromscratch.org/lfs/view/development/chapter02/creatingpartition.html
apt-get install -y apt-utils parted udev
bash /vagrant/2.4-creating-a-new-partition.sh
# Format and mount the partition
# See https://www.linuxfromscratch.org/lfs/view/development/chapter02/mounting.html
bash /vagrant/2.7-mounting-the-new-partition.sh
# Install dependencies mentioned in jhalfs README 2. PREREQUISITIES
DEBIAN_FRONTEND=noninteractive apt-get install -y wget sudo libxml2 libxslt-dev docbook-xml docbook-xsl-nons
# Install jhalfs dependencies, undocumented in jhalfs
DEBIAN_FRONTEND=noninteractive apt-get install -y git make python3 gcc libxml2-utils xsltproc
# Clone jhalfs and copy configuration. The requests tend to fail
# fatal: unable to access 'https://git.linuxfromscratch.org/jhalfs.git/': Could not resolve host: git.linuxfromscratch.org
su - vagrant -c 'cd /home/vagrant && if test ! -d lhafs; then while ! $(curl -s --max-time 5 -L git.linuxfromscratch.org > /dev/null); do echo Trying to reach git.linuxfromscratch.org ...  && sleep 5; done && git clone https://git.linuxfromscratch.org/jhalfs.git jhalfs; fi'
su - vagrant -c 'cp /vagrant/configuration /home/vagrant/jhalfs'
# Install lfs host requirements, undocumented in jhalfs
# See https://www.linuxfromscratch.org/lfs/view/systemd/chapter02/hostreqs.html
DEBIAN_FRONTEND=noninteractive apt-get install -y bison coreutils diffutils findutils gawk g++ grep gzip m4 make patch perl python3 sed tar texinfo xz-utils
# Generate the jhalfs makefiles under $LFS
# Downloading of patches tends to fail, run the scripts twice
# Resolving www.linuxfromscratch.org (www.linuxfromscratch.org)... failed: Temporary failure in name resolution.
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd /home/vagrant/jhalfs && while ! $(curl -s --max-time 5 -L www.linuxfromscratch.org > /dev/null); do echo Trying to reach www.linuxfromscratch.org ...  && sleep 5; done && yes yes | ./jhalfs run'
su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd /home/vagrant/jhalfs && while ! $(curl -s --max-time 5 -L www.linuxfromscratch.org > /dev/null); do echo Trying to reach www.linuxfromscratch.org ...  && sleep 5; done && yes yes | ./jhalfs run'
# Extract the jhalfs make targets
source jhalfs.sh
grep $'all:\t' $LFS/jhalfs/Makefile | cut -d: -f 2- | xargs > targets

# Mark as done by creating a file
touch up
