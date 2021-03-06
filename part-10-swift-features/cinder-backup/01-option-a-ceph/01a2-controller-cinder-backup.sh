#!/bin/bash
# enable cinder backups for ceph

source ~/os-env

mv ~/ceph.client.ecbackup.keyring /etc/ceph
mv ~/client.ecbackup.key /etc/ceph

chgrp cinder /etc/ceph/ceph.client.ecbackup.keyring
chmod 640 /etc/ceph/ceph.client.ecbackup.keyring

cat << EOF >> /etc/ceph/ceph.conf

[client.ecbackup]
keyring = /etc/ceph/ceph.client.ecbackup.keyring
rbd default data pool = ecbackup_data
EOF

# conf file work

./conf.sh /etc/cinder/cinder.conf DEFAULT backup_driver cinder.backup.drivers.ceph.CephBackupDriver
./conf.sh /etc/cinder/cinder.conf DEFAULT backup_ceph_user ecbackup
./conf.sh /etc/cinder/cinder.conf DEFAULT backup_ceph_pool ecbackup
./conf.sh /etc/cinder/cinder.conf DEFAULT backup_ceph_conf /etc/ceph/ceph.conf

# enable and start backup service

for i in enable start;do systemctl $i openstack-cinder-backup;done

exit
