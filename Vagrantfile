# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  # UCP 2.1 node for DDC
    config.vm.define "ucp-vancouver-node1" do |ucp_vancouver_node1|
      ucp_vancouver_node1.vm.box = "ubuntu/xenial64"
      ucp_vancouver_node1.vm.network "private_network", ip: "172.28.128.10"
      ucp_vancouver_node1.vm.hostname = "ucp.demo-gods.com/
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "2048"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
         vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
         vb.name = "ucp-vancouver-node1"
      end
      ucp_vancouver_node1.vm.provision "shell", inline: <<-SHELL
        sudo apt-get install -y apt-transport-https ca-certificates ntpdate curl software-properties-common
        sudo ntpdate -s time.nist.gov
        export DOCKER_EE_URL=$(cat /vagrant/ee_url)
        sudo curl -fsSL ${DOCKER_EE_URL}/gpg | sudo apt-key add
        sudo add-apt-repository "deb [arch=amd64] ${DOCKER_EE_URL} $(lsb_release -cs) stable-17.03"
        sudo apt-get update
        sudo apt-get -y install docker-ee
        sudo usermod -aG docker ubuntu
        ifconfig enp0s8 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' > /vagrant/ucp-vancouver-node1-ipaddr
        export UCP_IPADDR=$(cat /vagrant/ucp-vancouver-node1-ipaddr)
        export UCP_PASSWORD=$(cat /vagrant/ucp_password)
        export HUB_USERNAME=$(cat /vagrant/hub_username)
        export HUB_PASSWORD=$(cat /vagrant/hub_password)
        sudo sh -c "echo '${UCP_IPADDR} ucp.demo-gods.com ucp' >> /etc/hosts"
        sudo sh -c "echo '172.28.128.11 dtr.demo-gods.com dtr' >> /etc/hosts"
        docker login -u ${HUB_USERNAME} -p ${HUB_PASSWORD}
        docker pull docker/ucp:2.1.3
	docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:2.1.3 install --host-address ${UCP_IPADDR} --admin-password ${UCP_PASSWORD} --san ucp.demo-gods.com --license $(cat /vagrant/docker_subscription.lic)
        docker swarm join-token manager | awk -F " " '/token/ {print $2}' > /vagrant/swarm-join-token-mgr
        docker swarm join-token worker | awk -F " " '/token/ {print $2}' > /vagrant/swarm-join-token-worker
        docker run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:2.1.3 id | awk '{ print $1}' > /vagrant/ucp-vancouver-id
        export UCP_ID=$(cat /vagrant/ucp-vancouver-id)
        docker run --rm -i --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:2.1.3 backup --id ${UCP_ID} --root-ca-only --passphrase "secret" > /vagrant/backup.tar
     SHELL
    end

    # DTR Node 1 for DDC setup
    config.vm.define "dtr-vancouver-node1" do |dtr_vancouver_node1|
      dtr_vancouver_node1.vm.box = "ubuntu/xenial64"
      dtr_vancouver_node1.vm.network "private_network", ip: "172.28.128.11"
      dtr_vancouver_node1.vm.hostname = "dtr.demo-gods.com"
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "2048"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
         vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
         vb.name = "dtr-vancouver-node1"
      end
      dtr_vancouver_node1.vm.provision "shell", inline: <<-SHELL
        sudo apt-get install -y apt-transport-https ca-certificates ntpdate curl software-properties-common
        sudo ntpdate -s time.nist.gov
        export DOCKER_EE_URL=$(cat /vagrant/ee_url)
        sudo curl -fsSL ${DOCKER_EE_URL}/gpg | sudo apt-key add
        sudo add-apt-repository "deb [arch=amd64] ${DOCKER_EE_URL} $(lsb_release -cs) stable-17.03"
        sudo apt-get update
        sudo apt-get -y install docker-ee
        sudo usermod -aG docker ubuntu
        # Login to Hub
        export HUB_USERNAME=$(cat /vagrant/hub_username)
        export HUB_PASSWORD=$(cat /vagrant/hub_password)
        docker login -u ${HUB_USERNAME} -p ${HUB_PASSWORD}
        # Join UCP Swarm
        ifconfig enp0s8 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' > /vagrant/dtr-vancouver-node1-ipaddr
        cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 12 | head -n 1 > /vagrant/dtr-replica-id
        export UCP_PASSWORD=$(cat /vagrant/ucp_password)
        export UCP_IPADDR=$(cat /vagrant/ucp-vancouver-node1-ipaddr)
        export UCP_URL=https://ucp.demo-gods.com
        export DTR_URL=https://dtr.demo-gods.com
        export DTR_IPADDR=$(cat /vagrant/dtr-vancouver-node1-ipaddr)
        export SWARM_JOIN_TOKEN_WORKER=$(cat /vagrant/swarm-join-token-worker)
        export DTR_REPLICA_ID=$(cat /vagrant/dtr-replica-id)
        sudo sh -c "echo '${UCP_IPADDR} ucp.demo-gods.com' >> /etc/hosts"
        sudo sh -c "echo '${DTR_IPADDR} dtr.demo-gods.com' >> /etc/hosts"
        docker pull docker/ucp:2.1.3
        docker swarm join --token ${SWARM_JOIN_TOKEN_WORKER} ${UCP_IPADDR}:2377
        # Wait for Join to complete
        sleep 30
        # Install DTR
        curl -k https://${UCP_IPADDR}/ca > ucp-ca.pem
        docker run --rm docker/dtr:2.2.4 install --hub-username ${HUB_USERNAME} --hub-password ${HUB_PASSWORD} --ucp-url https://${UCP_IPADDR} --ucp-node dtr --replica-id ${DTR_REPLICA_ID} --dtr-external-url https://${DTR_IPADDR} --ucp-username admin --ucp-password ${UCP_PASSWORD} --ucp-ca "$(cat ucp-ca.pem)"
        # Run backup of DTR
        docker run --rm docker/dtr:2.2.4 backup --ucp-url https://${UCP_IPADDR} --existing-replica-id ${DTR_REPLICA_ID} --ucp-username admin --ucp-password ${UCP_PASSWORD} --ucp-ca "$(cat ucp-ca.pem)" > /tmp/backup.tar
        # Trust self-signed DTR CA
        openssl s_client -connect ${DTR_IPADDR}:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM | sudo tee /usr/local/share/ca-certificates/${DTR_IPADDR}.crt
        sudo update-ca-certificates
        sudo service docker restart
        # Copy convenience scripts
        sudo cp -r /vagrant/scripts /home/ubuntu/scripts
      SHELL
    end

    # Application Worker Node 1
    config.vm.define "worker-node1" do |worker_node1|
      worker_node1.vm.box = "ubuntu/xenial64"
      worker_node1.vm.network "private_network", ip: "172.28.128.12"
      worker_node1.vm.hostname = "worker-node1.demo-gods.com"
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "2048"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
         vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
         vb.name = "worker-node1"
      end
      worker_node1.vm.provision "shell", inline: <<-SHELL
        sudo apt-get install -y apt-transport-https ca-certificates ntpdate curl software-properties-common
        sudo ntpdate -s time.nist.gov
        export DOCKER_EE_URL=$(cat /vagrant/ee_url)
        sudo curl -fsSL ${DOCKER_EE_URL}/gpg | sudo apt-key add
        sudo add-apt-repository "deb [arch=amd64] ${DOCKER_EE_URL} $(lsb_release -cs) stable-17.03"
        sudo apt-get update
        sudo apt-get -y install docker-ee
        sudo usermod -aG docker ubuntu
        ifconfig enp0s8 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' > /vagrant/worker-node1-ipaddr
        export HUB_USERNAME=$(cat /vagrant/hub_username)
        export HUB_PASSWORD=$(cat /vagrant/hub_password)
        docker login -u ${HUB_USERNAME} -p ${HUB_PASSWORD}
        docker pull docker/ucp:2.1.3
        # Join Swarm as worker
        export UCP_IPADDR=$(cat /vagrant/ucp-vancouver-node1-ipaddr)
        export DTR_IPADDR=$(cat /vagrant/dtr-vancouver-node1-ipaddr)
        export SWARM_JOIN_TOKEN_WORKER=$(cat /vagrant/swarm-join-token-worker)
        docker swarm join --token ${SWARM_JOIN_TOKEN_WORKER} ${UCP_IPADDR}:2377
        # Trust self-signed DTR CA
        openssl s_client -connect ${DTR_IPADDR}:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM | sudo tee /usr/local/share/ca-certificates/${DTR_IPADDR}.crt
        sudo update-ca-certificates
        sudo service docker restart
     SHELL
    end

    # Application Worker Node 2
    config.vm.define "worker-node2" do |worker_node2|
      worker_node2.vm.box = "ubuntu/xenial64"
      worker_node2.vm.network "private_network", ip: "172.28.128.13"
      worker_node2.vm.hostname = "worker-node2.demo-gods.com"
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "2048"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
         vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
         vb.name = "worker-node2"
      end
      worker_node2.vm.provision "shell", inline: <<-SHELL
        sudo apt-get install -y apt-transport-https ca-certificates ntpdate curl software-properties-common jq zip
        sudo ntpdate -s time.nist.gov
        export DOCKER_EE_URL=$(cat /vagrant/ee_url)
        sudo curl -fsSL ${DOCKER_EE_URL}/gpg | sudo apt-key add
        sudo add-apt-repository "deb [arch=amd64] ${DOCKER_EE_URL} $(lsb_release -cs) stable-17.03"
        sudo apt-get update
        sudo apt-get -y install docker-ee
        sudo usermod -aG docker ubuntu
        ifconfig enp0s8 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' > /vagrant/worker-node2-ipaddr
        export HUB_USERNAME=$(cat /vagrant/hub_username)
        export HUB_PASSWORD=$(cat /vagrant/hub_password)
        docker login -u ${HUB_USERNAME} -p ${HUB_PASSWORD}
        docker pull docker/ucp:2.1.3
        # Join Swarm as worker
        export UCP_PASSWORD=$(cat /vagrant/ucp_password)
        export UCP_IPADDR=$(cat /vagrant/ucp-vancouver-node1-ipaddr)
        export DTR_IPADDR=$(cat /vagrant/dtr-vancouver-node1-ipaddr)
        export SWARM_JOIN_TOKEN_WORKER=$(cat /vagrant/swarm-join-token-worker)
        export WORKER_NODE_NAME=$(hostname)
        docker swarm join --token ${SWARM_JOIN_TOKEN_WORKER} ${UCP_IPADDR}:2377
        # Trust self-signed DTR CA
        openssl s_client -connect ${DTR_IPADDR}:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM | sudo tee /usr/local/share/ca-certificates/${DTR_IPADDR}.crt
        sudo update-ca-certificates
        sudo service docker restart
        # Install Notary
        curl -L https://github.com/docker/notary/releases/download/v0.4.3/notary-Linux-amd64 > /home/ubuntu/notary
        chmod +x /home/ubuntu/notary
        # Create jenkins folder to store Jenkins container config
        sudo mkdir /home/ubuntu/jenkins
        # Create notary foldoer to store trust config
        sudo mkdir -p /home/ubuntu/notary-config/.docker/trust
        # Download UCP client bundle
        echo "Retrieving authtoken"
        export AUTHTOKEN=$(curl -sk -d '{"username":"admin","password":"'"${UCP_PASSWORD}"'"}' https://${UCP_IPADDR}/auth/login | jq -r .auth_token)
        sudo mkdir ucp-bundle-admin
        echo "Downloading ucp bundle"
        sudo curl -k -H "Authorization: Bearer ${AUTHTOKEN}" https://${UCP_IPADDR}/api/clientbundle -H 'accept: application/json, text/plain, */*' --insecure > /home/ubuntu/ucp-bundle-admin/bundle.zip
        sudo unzip /home/ubuntu/ucp-bundle-admin/bundle.zip -d /home/ubuntu/ucp-bundle-admin/
        sudo rm -f /home/ubuntu/ucp-bundle-admin/bundle.zip
        # Authenticate to UCP Swarm
        export DOCKER_TLS_VERIFY=1
        export DOCKER_CERT_PATH="/home/ubuntu/ucp-bundle-admin"
        export DOCKER_HOST=tcp://${UCP_IPADDR}:443
        # Add Jenkins label to worker node
        docker node update --label-add jenkins=master worker-node2
        # Deploy Jenkins as a container
        sudo cp -r /vagrant/scripts/ /home/ubuntu/scripts
        docker service create --name leroy-jenkins --network ucp-hrm --publish 8080:8080 \
          --mount type=bind,source=/home/ubuntu/jenkins,destination=/var/jenkins_home \
          --mount type=bind,source=/home/ubuntu/notary-config/.docker/trust,destination=/root/.docker/trust \
          --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock \
          --mount type=bind,source=/usr/bin/docker,destination=/usr/bin/docker \
          --mount type=bind,source=/home/ubuntu/ucp-bundle-admin,destination=/home/jenkins/ucp-bundle-admin \
          --mount type=bind,source=/home/ubuntu/scripts,destination=/home/jenkins/scripts \
          --mount type=bind,source=/home/ubuntu/notary,destination=/usr/local/bin/notary \
          --label com.docker.ucp.mesh.http.8080=external_route=http://jenkins.demo-gods.com,internal_port=8080 \
          --constraint 'node.labels.jenkins == master' yongshin/leroy-jenkins
        # Have Jenkins trust DTR
        export JENKINS_CONTAINER_ID=$(docker ps | grep leroy-jenkins | awk '{ print $1}')
        docker exec -it ${JENKINS_CONTAINER_ID} /bin/sh -c "export DTR_IPADDR=${DTR_IPADDR}; ./home/jenkins/scripts/trust-dtr.sh"
     SHELL
    end

    # Application Worker Node 3
    config.vm.define "worker-node3" do |worker_node3|
      worker_node3.vm.box = "ubuntu/xenial64"
      worker_node3.vm.network "private_network", ip: "172.28.128.14"
      worker_node3.vm.hostname = "worker-node3.demo-gods.com"
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "2048"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
         vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
         vb.name = "worker-node3"
      end
      worker_node3.vm.provision "shell", inline: <<-SHELL
        sudo apt-get install -y apt-transport-https ca-certificates ntpdate curl software-properties-common
        sudo ntpdate -s time.nist.gov
        export DOCKER_EE_URL=$(cat /vagrant/ee_url)
        sudo curl -fsSL ${DOCKER_EE_URL}/gpg | sudo apt-key add
        sudo add-apt-repository "deb [arch=amd64] ${DOCKER_EE_URL} $(lsb_release -cs) stable-17.03"
        sudo apt-get update
        sudo apt-get -y install docker-ee
        sudo usermod -aG docker ubuntu
        ifconfig enp0s8 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' > /vagrant/worker-node3-ipaddr
        export HUB_USERNAME=$(cat /vagrant/hub_username)
        export HUB_PASSWORD=$(cat /vagrant/hub_password)
        docker login -u ${HUB_USERNAME} -p ${HUB_PASSWORD}
        docker pull docker/ucp:2.1.3
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
     SHELL
    end

end
