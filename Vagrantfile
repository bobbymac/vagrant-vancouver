# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  # UCP 2.1 node for DDC
    config.vm.define "ucp-vancouver-node1" do |ucp_vancouver_node1|
      ucp_vancouver_node1.vm.box = "ubuntu/xenial64"
      ucp_vancouver_node1.vm.network "private_network", ip: "172.28.128.10"
      ucp_vancouver_node1.vm.hostname = "ucp.demo-gods.com
      config.vm.provider :virtualbox do |vb|
         v.memory = 2048
         v.cpus = 2
         v.name = "ucp"
      end
      ucp_vancouver_node1.vm.provision "shell", path: "scripts/ucpscript.sh"
    end

    # DTR Node 1 for DDC setup
    config.vm.define "dtr-vancouver-node1" do |dtr_vancouver_node1|
      dtr_vancouver_node1.vm.box = "ubuntu/xenial64"
      dtr_vancouver_node1.vm.network "private_network", ip: "172.28.128.11"
      dtr_vancouver_node1.vm.hostname = "dtr.demo-gods.com"
      config.vm.provider :virtualbox do |vb|
         v.memory = 2048
         v.cpus = 2
         v.name = "dtr-vancouver-node1"
      end
      dtr_vancouver_node1.vm.provision "shell", path: "scripts/dtrscript.sh"
    end

    # Application Worker Node 1
    config.vm.define "worker-node1" do |worker_node1|
      worker_node1.vm.box = "ubuntu/xenial64"
      worker_node1.vm.network "private_network", ip: "172.28.128.12"
      worker_node1.vm.hostname = "worker-node1.demo-gods.com"
      config.vm.provider :virtualbox do |vb|
         v.memory = 2048
         v.cpus = 2
         v.name = "worker-node1"
      end
      worker_node1.vm.provision "shell", path: "scripts/worker-node1.sh"
    end

    # Application Worker Node 2
    config.vm.define "worker-node2" do |worker_node2|
      worker_node2.vm.box = "ubuntu/xenial64"
      worker_node2.vm.network "private_network", ip: "172.28.128.13"
      worker_node2.vm.hostname = "worker-node2.demo-gods.com"
      config.vm.provider :virtualbox do |vb|
         v.memory = 2048
         v.cpus = 2
         v.name = "worker-node2"
      end
      worker_node2.vm.provision "shell", path: "scripts/worker-node2.sh"
    end

    # Application Worker Node 3
    config.vm.define "worker-node3" do |worker_node3|
      worker_node3.vm.box = "ubuntu/xenial64"
      worker_node3.vm.network "private_network", ip: "172.28.128.14"
      worker_node3.vm.hostname = "worker-node3.demo-gods.com"
      config.vm.provider :virtualbox do |vb|
         v.memory = 2048
         v.cpus = 2
         v.name = "worker-node3"
      end
      worker_node3.vm.provision "shell", path: "scripts/worker-node3.sh"
     SHELL
    end

end
