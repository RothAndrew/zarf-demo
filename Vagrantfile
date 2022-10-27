# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vb|
    vb.check_guest_additions = false
    vb.cpus = 5
    vb.memory = 8000
  end
  config.vm.box = "generic/rocky8"
  config.vm.disk :disk, size: "50GB", primary: true
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder "./build", "/cmdnet-zarf-poc", SharedFoldersEnableSymlinksCreate: false
  config.vm.hostname = "cmdnet-zarf-poc"
  config.ssh.insert_key = false
  config.ssh.extra_args = [ "-t", "cd /cmdnet-zarf-poc; sudo su" ]
  config.vm.provision "shell", inline: <<-SHELL
    # Install some tools
    dnf install -y cloud-utils-growpart

    # Update the partition to fill the available disk
    growpart /dev/sda 1 && resize2fs /dev/sda1

    # Increase vm_max_map_count for tools like elasticsearch
    sysctl -w vm.max_map_count=262144

    # Simulate an airgap
    ip link add airgap type dummy && ip link set airgap up && ip -c address add 1.1.1.1/16 dev airgap && ip route add default via 1.1.1.1 dev airgap metric 1
  SHELL
end
