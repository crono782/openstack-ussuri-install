#!/bin/sh

source ~/os-env

# prob should switch to new glance multistore setup
# [DEFAULT] enabled_backends = name:type
# [glance_store] default_backend = name
# [name] key/value options

dnf -y install python3-rbd

# not sure if need to create ceph user and sudo rule
# useradd ceph
# passwd ceph
# cat << EOF >/etc/sudoers.d/ceph
# ceph ALL = (root) NOPASSWD:ALL
# Defaults:ceph !requiretty
# EOF
# chmod 440 /etc/sudoers.d/ceph

# on ceph node

source ~/os-env

ceph osd pool create volumes 32
ceph auth get-or-create client.volumes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images' -o /etc/ceph/ceph.client.volumes.keyring

scp /etc/ceph/ceph.client.volumes.keyring $OS_CONTROLLER_NM:/etc/ceph

ceph auth get-key client.volumes|ssh $OS_CONTROLLER_NM tee /etc/ceph/client.volumes.key

# on controller

chgrp cinder /etc/ceph/ceph.client.volumes.keyring
chmod 640 /etc/ceph/ceph.client.volumes.keyring

cat << EOF >> /etc/ceph/ceph.conf

[client.volumes]
keyring = /etc/ceph/ceph.client.volumes.keyring
EOF

uuidgen |tee /etc/ceph/cinder.uuid.txt

cp -p /etc/cinder/cinder.conf /etc/cinder/cinder.conf.preceph

./conf.sh /etc/cinder/cinder.conf DEFAULT enabled_backends rbd
./conf.sh /etc/cinder/cinder.conf rbd volume_backend_name Ceph-RBD
./conf.sh /etc/cinder/cinder.conf rbd volume_driver cinder.volume.drivers.rbd.RBDDriver
./conf.sh /etc/cinder/cinder.conf rbd rbd_pool volumes
./conf.sh /etc/cinder/cinder.conf rbd rbd_user volumes
./conf.sh /etc/cinder/cinder.conf rbd rbd_secret_uuid "$(cat /etc/ceph/cinder.uuid.txt)"
./conf.sh /etc/cinder/cinder.conf rbd rbd_ceph_conf /etc/ceph/ceph.conf

systemctl enable openstack-cinder-volume
systemctl restart openstack-cinder-{api,volume}

scp /etc/ceph/cinder.uuid.txt $OS_COMPUTE_NM:~
scp /etc/ceph/client.volumes.key $OS_COMPUTE_NM:~
rm -f /etc/ceph/cinder.uuid.txt
rm -f /etc/ceph/client.volumes.key

# on compute node

cat << EOF > ~/ceph.xml
<secret ephemeral="no" private="no">
  <uuid>$(cat ~/cinder.uuid.txt)</uuid>
  <usage type="ceph">
    <name>client.volumes secret</name>
  </usage>
</secret>
EOF 

virsh secret-define --file ~/ceph.xml

virsh secret-set-value --secret $(cat ~/cinder.uuid.txt) --base64 $(cat ~/client.volumes.key)

rm -f ~/{cinder.uuid.txt,ceph.xml,client.volumes.key}



