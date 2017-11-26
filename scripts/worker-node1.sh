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
