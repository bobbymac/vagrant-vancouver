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
