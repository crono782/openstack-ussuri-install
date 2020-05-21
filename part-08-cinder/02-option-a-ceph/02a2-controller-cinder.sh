#!/bin/sh

# OPTION A: CEPH BACKED CINDER

source ~/os-env

dnf -y install epel-release
dnf -y install python3-rbd

if [ ! -f /etc/ceph/ceph.conf ]; then
  mv ~/ceph.conf /etc/ceph
fi
mv ~/ceph.client.volumes.keyring /etc/ceph
mv ~/ceph.client.ecvolumes.keyring /etc/ceph

chgrp cinder /etc/ceph/ceph.client.volumes.keyring
chmod 640 /etc/ceph/ceph.client.volumes.keyring

chgrp cinder /etc/ceph/ceph.client.ecvolumes.keyring
chmod 640 /etc/ceph/ceph.client.ecvolumes.keyring

cat << EOF >> /etc/ceph/ceph.conf

[client.volumes]
keyring = /etc/ceph/ceph.client.volumes.keyring

[client.ecvolumes]
keyring = /etc/ceph/ceph.client.ecvolumes.keyring
rbd default data pool = ecvolumes_data
EOF

uuidgen |tee /etc/ceph/cinder.volumes.uuid.txt
uuidgen |tee /etc/ceph/cinder.ecvolumes.uuid.txt

./conf.sh /etc/cinder/cinder.conf DEFAULT enabled_backends rbd,ecrbd
./conf.sh /etc/cinder/cinder.conf DEFAULT default_volume_type Standard-CephRBD 

./conf.sh /etc/cinder/cinder.conf rbd volume_backend_name CephRBD
./conf.sh /etc/cinder/cinder.conf rbd volume_driver cinder.volume.drivers.rbd.RBDDriver
./conf.sh /etc/cinder/cinder.conf rbd rbd_pool volumes
./conf.sh /etc/cinder/cinder.conf rbd rbd_user volumes
./conf.sh /etc/cinder/cinder.conf rbd rbd_secret_uuid "$(cat /etc/ceph/cinder.volumes.uuid.txt)"
./conf.sh /etc/cinder/cinder.conf rbd rbd_ceph_conf /etc/ceph/ceph.conf

./conf.sh /etc/cinder/cinder.conf ecrbd volume_backend_name CephRBD-EC
./conf.sh /etc/cinder/cinder.conf ecrbd volume_driver cinder.volume.drivers.rbd.RBDDriver
./conf.sh /etc/cinder/cinder.conf ecrbd rbd_pool ecvolumes
./conf.sh /etc/cinder/cinder.conf ecrbd rbd_user ecvolumes
./conf.sh /etc/cinder/cinder.conf ecrbd rbd_secret_uuid "$(cat /etc/ceph/cinder.ecvolumes.uuid.txt)"
./conf.sh /etc/cinder/cinder.conf ecrbd rbd_ceph_conf /etc/ceph/ceph.conf

systemctl enable openstack-cinder-volume
systemctl restart openstack-cinder-{api,volume}

scp /etc/ceph/cinder.volumes.uuid.txt $OS_COMPUTE_NM:~
scp /etc/ceph/cinder.ecvolumes.uuid.txt $OS_COMPUTE_NM:~
scp /etc/ceph/client.volumes.key $OS_COMPUTE_NM:~
scp /etc/ceph/client.ecvolumes.key $OS_COMPUTE_NM:~
rm -f /etc/ceph/cinder.volumes.uuid.txt
rm -f /etc/ceph/cinder.ecvolumes.uuid.txt
rm -f /etc/ceph/client.volumes.key
rm -f /etc/ceph/client.ecvolumes.key

