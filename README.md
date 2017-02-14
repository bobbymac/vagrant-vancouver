Vagrant Virtualbox setup for UCP 2.1.0 and DTR 2.2.1
========================

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

## Setup /etc/hosts  
```
sudo vi /private/etc/hosts
```

Add hosts for DTR, UCP, and Jenkins
```
#/etc/hosts
172.28.128.3 wordpress.local
172.28.128.3 jenkins.local
172.28.128.3 ucp.local
172.28.128.3 dtr.local
```

```
sudo killall -HUP mDNSResponder
```

## Bring up/Resume UCP, DTR, and Jenkins nodes

```
vagrant up ucp-vancouver-node1 dtr-vancouver-node1 worker-node1
```

## Stop UCP, DTR, and Jenkins nodes

```
vagrant halt ucp-vancouver-node1 dtr-vancouver-node1 worker-node1
```

## Destroy UCP, DTR, and Jenkins nodes

```
vagrant destroy ucp-vancouver-node1 dtr-vancouver-node1 worker-node1
```
