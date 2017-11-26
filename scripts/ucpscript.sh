#UCP config file used by Vagrantfile
sudo apt-get install -y apt-transport-https ca-certificates ntpdate curl software-properties-common
sudo ntpdate -s time.nist.gov
export DOCKER_EE_URL=$(cat /vagrant/ee_url)
sudo wget ${DOCKER_EE_URL}/gpg | sudo apt-key add
sudo add-apt-repository "deb [arch=amd64] ${DOCKER_EE_URL} $(lsb_release -cs) stable-17.06"
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
