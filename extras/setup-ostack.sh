#!/bin/sh

source ~/adminrc

wget http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img
qemu-img convert cirros-0.5.1-x86_64-disk.img cirros-0.5.1-x86_64-disk.raw
openstack image create "cirros" --file cirros-0.5.1-x86_64-disk.raw --disk-format raw --container-format bare --public
rm -f cirros-0.5.1-x86_64-disk.{img,raw}

openstack flavor create --disk 1 --ram 256 --vcpus 1 m1.nano

openstack network create --external --provider-network-type flat --provider-physical-network provider provider
openstack subnet create --network provider --subnet-range 203.0.113.0/24 --gateway 203.0.113.1 --allocation-pool start=203.0.113.10,end=203.0.113.100 --dns-nameserver 8.8.8.8 provider

source ~/demorc

openstack network create selfservice
openstack subnet create --network selfservice --subnet-range 10.10.100.0/24 --gateway 10.10.100.1 --dns-nameserver 8.8.8.8 selfservice

openstack router create router1
openstack router add subnet router1 selfservice
openstack router set router1 --external-gateway provider

openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

ssh-keygen -q -N "" -f testkey
openstack keypair create --public-key testkey.pub testkey

openstack server create --flavor m1.nano --network selfservice --image cirros --key-name testkey inst1

exit
