# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.define "jhalfs" do |machine|
    machine.vm.provider "docker" do |d|
      #d.build_dir = "."
      d.cmd = ["sleep", "infinity"]
      d.create_args = ["--privileged"]  # Require to create loopback devices in the container
      d.image = "ubuntu:latest"
      d.name = "jhalfs"
    end
    machine.vm.synced_folder '.', '/vagrant', disabled: false
  end
end

# TODO:
# vagrant docker-exec -it -- bash /vagrant/up.sh
# vagrant docker-exec -it -- bash -c "cd /vagrant && bash /vagrant/up.sh"
# remove: for dev in $(losetup -n -O NAME -j /jhalfs/build_dir.img); do losetup -v -d $dev; done
# retry patch download: yes yes | ./jhalfs run
# time while [ ! -f up ]; do echo "Wait for up to complete: $(date --iso-8601=seconds)" && sleep 30; done
# vagrant docker-exec -it -- bash -c "su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd $LFS/jhalfs && make ck_UID'"
