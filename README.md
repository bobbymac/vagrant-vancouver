Vagrant Virtualbox setup for Docker EE 17.03, UCP 2.1.0 and DTR 2.2.3
========================

The following set of instructions helps Docker DataCenter across multiple vms with static ip addresses:

* UCP - ucp.local on 172.28.128.10
* DTR - dtr.local on 172.28.128.11
* Worker node - worker-node1 on 172.28.128.12
* Worker node - worker-node2 on 172.28.128.13
* Worker node - worker-node3 on 172.28.128.14

## Download vagrant from Vagrant website

```
https://www.vagrantup.com/downloads.html
```

## Install Virtual Box

```
https://www.virtualbox.org/wiki/Downloads
```

## Download Xenial box
```
vagrant init ubuntu/xenial64
```

## Install Vagrant Plugins
```
vagrant plugin install vagrant-hostsupdater
vagrant plugin install vagrant-multiprovider-snap
```

## Create files in project to store environment variables with custom values for use by Vagrant
```
hub_username
hub_password
ucp_password
ee_url
```

## Bring up/Resume UCP, DTR, and Jenkins nodes

```
vagrant up ucp-vancouver-node1 dtr-vancouver-node1 worker-node1 worker-node2
```

## Stop UCP, DTR, and Jenkins nodes

```
vagrant halt ucp-vancouver-node1 dtr-vancouver-node1 worker-node1 worker-node2
```

## Destroy UCP, DTR, and Jenkins nodes

```
vagrant destroy ucp-vancouver-node1 dtr-vancouver-node1 worker-node1 worker-node2
```
