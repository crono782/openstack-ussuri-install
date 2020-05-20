#!/bin/sh

# prob should switch to new glance multistore setup
# [DEFAULT] enabled_backends = name:type
# [glance_store] default_backend = name
# [name] key/value options

dnf -y install python3-rbd
pip3 install boto3  # maybe this should already be done. threw s3 errors

# not sure if need to create ceph user and sudo rule
# useradd ceph
# passwd ceph
# cat << EOF >/etc/sudoers.d/ceph
# ceph ALL = (root) NOPASSWD:ALL
# Defaults:ceph !requiretty
# EOF
# chmod 440 /etc/sudoers.d/ceph

# on ceph node
ceph osd pool create images 32
ceph auth get-or-create client.images mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images' -o /etc/ceph/ceph.client.images.keyring

scp /etc/ceph/ceph.client.images.keyring controller:/etc/ceph
scp /etc/ceph/ceph.conf controller:/etc/ceph

# on controller

chgrp glance /etc/ceph/ceph.client.images.keyring
chmod 640 /etc/ceph/ceph.client.images.keyring

cat << EOF >> /etc/ceph/ceph.conf

[client.images]
keyring = /etc/ceph/ceph.client.images.keyring
EOF

cp -p /etc/glance/glance-api.conf /etc/glance/glance-api.conf.preceph
# change enabled_backends to ceph:rbd
# change default_backend to ceph
# create [ceph] section
# rbd_store_pool = images
# rbd_store_user = images
# rbd_store_ceph_conf = /etc/ceph/ceph.conf

systemctl restart opentack-glance-api







