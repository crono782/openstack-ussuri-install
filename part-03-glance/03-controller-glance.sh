#!/bin/bash

source ~/adminrc

# sync database and start services

su -s /bin/sh -c "glance-manage db_sync" glance

for i in enable start;do systemctl $i openstack-glance-api;done

# download cirros test image and upload to glance for verification

dnf -y install wget

wget http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img

openstack image create "cirros" --file cirros-0.5.1-x86_64-disk.img --disk-format qcow2 --container-format bare --public

rm -f cirros-0.5.1-x86_64-disk.img

exit
