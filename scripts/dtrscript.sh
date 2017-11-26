#DTR config
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
sudo sh -c "echo '${UCP_IPADDR} ucp.demo-gods.com ucp' >> /etc/hosts"
sudo sh -c "echo '${DTR_IPADDR} dtr.demo-gods.com dtr' >> /etc/hosts"
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
