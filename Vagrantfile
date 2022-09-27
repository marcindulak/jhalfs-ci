# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.define "jhalfs" do |machine|
    machine.vm.provider "docker" do |d|
      d.cmd = ["sleep", "infinity"]
      d.create_args = ["--privileged"]  # Require to create loopback devices in the container
      d.image = "ubuntu:latest"
      d.name = "jhalfs"
    end
    machine.vm.synced_folder '.', '/vagrant', disabled: false
  end
end
