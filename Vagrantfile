# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  # UCP 2.1 node for DDC
    config.vm.define "ucp-vancouver-node1" do |ucp_vancouver_node1|
      ucp_vancouver_node1.vm.box = "ubuntu/xenial64"
      ucp_vancouver_node1.vm.network "private_network", type: "dhcp"
      ucp_vancouver_node1.vm.hostname = "ucp-vancouver-node1"
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "3072"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
         vb.name = "ucp-vancouver-node1"
      end
      ucp_vancouver_node1.vm.provision "shell", inline: <<-SHELL
       sudo apt-get update
       sudo apt-get install -y apt-transport-https ca-certificates
       sudo curl -fsSL https://packages.docker.com/1.13/install.sh | repo=testing sh
       sudo usermod -aG docker ubuntu
       ifconfig enp0s8 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' > /vagrant/ucp-vancouver-node1-ipaddr
       # Load UCP2 images
       # sudo cp /vagrant/ucp_images_2.1.0-tp2.tar.gz .
       # docker load < ucp_images_2.1.0-tp2.tar.gz
       export UCP_IPADDR=$(cat /vagrant/ucp-vancouver-node1-ipaddr)
       export UCP_PASSWORD=$(cat /vagrant/ucp_password)
       export HUB_USERNAME=$(cat /vagrant/hub_username)
       export HUB_PASSWORD=$(cat /vagrant/hub_password)
       docker login -u ${HUB_USERNAME} -p ${HUB_PASSWORD}
       docker pull docker/ucp:2.1.0-beta2
       docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock -v /vagrant/nautilus_beta.lic:/docker_subscription.lic docker/ucp:2.1.0-beta2 install --host-address ${UCP_IPADDR} --admin-password ${UCP_PASSWORD}
       docker swarm join-token manager | awk -F " " '/token/ {print $2}' > /vagrant/swarm-join-token-mgr
       docker swarm join-token worker | awk -F " " '/token/ {print $2}' > /vagrant/swarm-join-token-worker
       # Install registry certificates on client Docker daemon (only required for self-signed certs)
       # export DTR_IPADDR=$(cat /vagrant/dtr-vancouver-node1-ipaddr)
       # openssl s_client -connect ${DTR_IPADDR}:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM | sudo tee /usr/local/share/ca-certificates/${DTR_IPADDR}.crt
       # sudo update-ca-certificates
       # sudo service docker restart
       docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:2.1.0-beta2 id | awk '{ print $1}' > /vagrant/ucp-vancouver-id
       export UCP_ID=$(cat /vagrant/ucp-vancouver-id)
       docker run --rm -i --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:2.1.0-beta2 backup --id ${UCP_ID} --root-ca-only --passphrase "secret" > /vagrant/backup.tar
     SHELL
    end

    # DTR Node 1 for DDC setup
    config.vm.define "dtr-vancouver-node1" do |dtr_vancouver_node1|
      dtr_vancouver_node1.vm.box = "ubuntu/xenial64"
      dtr_vancouver_node1.vm.network "private_network", type: "dhcp"
      dtr_vancouver_node1.vm.hostname = "dtr-vancouver-node1"
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "3072"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
         vb.name = "dtr-vancouver-node1"
      end
      dtr_vancouver_node1.vm.provision "shell", inline: <<-SHELL
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates
        sudo curl -fsSL https://packages.docker.com/1.13/install.sh | repo=testing sh
        sudo usermod -aG docker ubuntu
        # Load UCP images to allow ucp-agent to run
        # sudo cp /vagrant/ucp_images_2.1.0-tp2.tar.gz .
        # docker load < ucp_images_2.1.0-tp2.tar.gz
        # Login to Hub
        ifconfig enp0s8 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' > /vagrant/dtr-vancouver-node1-ipaddr
        export HUB_USERNAME=$(cat /vagrant/hub_username)
        export HUB_PASSWORD=$(cat /vagrant/hub_password)
        docker login -u ${HUB_USERNAME} -p ${HUB_PASSWORD}
        # Join UCP Swarm
        cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 12 | head -n 1 > /vagrant/dtr-replica-id
        export UCP_PASSWORD=$(cat /vagrant/ucp_password)
        export UCP_IPADDR=$(cat /vagrant/ucp-vancouver-node1-ipaddr)
        export DTR_IPADDR=$(cat /vagrant/dtr-vancouver-node1-ipaddr)
        export SWARM_JOIN_TOKEN_WORKER=$(cat /vagrant/swarm-join-token-worker)
        export DTR_REPLICA_ID=$(cat /vagrant/dtr-replica-id)
        docker pull docker/ucp:2.1.0-beta2
        docker swarm join --token ${SWARM_JOIN_TOKEN_WORKER} ${UCP_IPADDR}:2377
        # Wait for Join to complete
        sleep 30
        # Install DTR
        curl -k https://${UCP_IPADDR}/ca > ucp-ca.pem
        docker run --rm docker/dtr:2.2.0-beta2 install --hub-username ${HUB_USERNAME} --hub-password ${HUB_PASSWORD} --ucp-url https://$UCP_IPADDR --ucp-node dtr-vancouver-node1 --replica-id $DTR_REPLICA_ID --dtr-external-url $DTR_IPADDR --ucp-username admin --ucp-password ${UCP_PASSWORD} --ucp-ca "$(cat ucp-ca.pem)"
        # Run backup of DTR
        docker run --rm docker/dtr:2.2.0-beta2 backup --ucp-url https://${UCP_IPADDR} --existing-replica-id ${DTR_REPLICA_ID} --ucp-username admin --ucp-password ${UCP_PASSWORD} --ucp-ca "$(cat ucp-ca.pem)" > /tmp/backup.tar
        # Trust self-signed DTR CA
        openssl s_client -connect ${DTR_IPADDR}:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM | sudo tee /usr/local/share/ca-certificates/${DTR_IPADDR}.crt
        sudo update-ca-certificates
        sudo service docker restart
      SHELL
    end

    # Application Worker Node 1
    config.vm.define "worker-node1" do |worker_node1|
      worker_node1.vm.box = "ubuntu/xenial64"
      worker_node1.vm.network "private_network", type: "dhcp"
      worker_node1.vm.hostname = "worker-node1"
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "2048"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
         vb.name = "worker-node1"
      end
      worker_node1.vm.provision "shell", inline: <<-SHELL
       sudo apt-get update
       sudo apt-get install -y apt-transport-https ca-certificates
       sudo curl -fsSL https://packages.docker.com/1.13/install.sh | repo=testing sh
       sudo usermod -aG docker ubuntu
       # Load UCP images to allow ucp-agent to run
       # sudo cp /vagrant/ucp_images_2.1.0-tp2.tar.gz .
       # docker load < ucp_images_2.1.0-tp2.tar.gz
       ifconfig enp0s8 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' > /vagrant/worker-node1-ipaddr
       export HUB_USERNAME=$(cat /vagrant/hub_username)
       export HUB_PASSWORD=$(cat /vagrant/hub_password)
       docker login -u ${HUB_USERNAME} -p ${HUB_PASSWORD}
       docker pull docker/ucp:2.1.0-beta2
       # Join Swarm as worker
       export UCP_IPADDR=$(cat /vagrant/ucp-vancouver-node1-ipaddr)
       export DTR_IPADDR=$(cat /vagrant/dtr-vancouver-node1-ipaddr)
       export SWARM_JOIN_TOKEN_WORKER=$(cat /vagrant/swarm-join-token-worker)
       docker swarm join --token ${SWARM_JOIN_TOKEN_WORKER} ${UCP_IPADDR}:2377
       # Trust self-signed DTR CA
       openssl s_client -connect ${DTR_IPADDR}:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM | sudo tee /usr/local/share/ca-certificates/${DTR_IPADDR}.crt
       sudo update-ca-certificates
       sudo service docker restart
       # Install Compose
       curl -L https://github.com/docker/compose/releases/download/1.10.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
       chmod +x /usr/local/bin/docker-compose
     SHELL
    end

    # Application Worker Node 2
    config.vm.define "worker-node2" do |worker_node2|
      worker_node2.vm.box = "ubuntu/xenial64"
      worker_node2.vm.network "private_network", type: "dhcp"
      worker_node2.vm.hostname = "worker-node2"
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "2048"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
         vb.name = "worker-node2"
      end
      worker_node2.vm.provision "shell", inline: <<-SHELL
       sudo apt-get update
       sudo apt-get install -y apt-transport-https ca-certificates
       sudo curl -fsSL https://packages.docker.com/1.13/install.sh | repo=testing sh
       sudo usermod -aG docker ubuntu
       # Load UCP images to allow ucp-agent to run
       # sudo cp /vagrant/ucp_images_2.1.0-tp2.tar.gz .
       # docker load < ucp_images_2.1.0-tp2.tar.gz
       ifconfig enp0s8 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' > /vagrant/worker-node1-ipaddr
       export HUB_USERNAME=$(cat /vagrant/hub_username)
       export HUB_PASSWORD=$(cat /vagrant/hub_password)
       docker login -u ${HUB_USERNAME} -p ${HUB_PASSWORD}
       docker pull docker/ucp:2.1.0-beta2
       # Join Swarm as worker
       export UCP_IPADDR=$(cat /vagrant/ucp-vancouver-node1-ipaddr)
       export DTR_IPADDR=$(cat /vagrant/dtr-vancouver-node1-ipaddr)
       export SWARM_JOIN_TOKEN_WORKER=$(cat /vagrant/swarm-join-token-worker)
       export WORKER_NODE_NAME=$(hostname)
       docker swarm join --token ${SWARM_JOIN_TOKEN_WORKER} ${UCP_IPADDR}:2377
       # Trust self-signed DTR CA
       openssl s_client -connect ${DTR_IPADDR}:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM | sudo tee /usr/local/share/ca-certificates/${DTR_IPADDR}.crt
       sudo update-ca-certificates
       sudo service docker restart
       # Install Compose
       curl -L https://github.com/docker/compose/releases/download/1.10.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
       chmod +x /usr/local/bin/docker-compose
       # Install Notary
       curl -L https://github.com/docker/notary/releases/download/v0.4.3/notary-Linux-amd64 > /usr/local/bin/notary
       chmod +x /usr/local/bin/notary
       # Configure node for Jenkins deployment
       sudo mkdir /home/ubuntu/jenkins
       docker node update --label-add type=jenkins ${WORKER_NODE_NAME}
     SHELL
    end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

end
