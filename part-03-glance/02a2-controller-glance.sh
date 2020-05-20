#!/bin/bash

# OPTION A: CEPH RBD BACKED GLANCE

source ~/os-env

dnf -y install epel-release
dnf -y install python3-rbd
pip3 install boto3 

./conf.sh /etc/glance/glance-api.conf DEFAULT enabled_backends ceph:rbd
./conf.sh /etc/glance/glance-api.conf glance_store default_backend ceph
./conf.sh /etc/glance/glance-api.conf ceph rbd_store_pool images
./conf.sh /etc/glance/glance-api.conf ceph rbd_store_user images
./conf.sh /etc/glance/glance-api.conf ceph rbd_store_ceph_conf /etc/ceph/ceph.conf

mv ~/ceph.conf /etc/ceph
mv ~/ceph.client.images.keyring /etc/ceph
chgrp glance /etc/ceph/ceph.client.images.keyring
chmod 640 /etc/ceph/ceph.client.images.keyring

cat << EOF >> /etc/ceph/ceph.conf

[client.images]
keyring = /etc/ceph/ceph.client.images.keyring
EOF

exit