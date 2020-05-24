#!/bin/bash
# enable cinder backups for ceph

source ~/os-env

ceph osd erasure-code-profile set os-vol-bu k=2 m=1 plugin=jerasure crush-failure-domain=osd technique=reed_sol_van

# create pools for erasure coded volumes

ceph osd pool create ecbackup 8
ceph osd pool create ecbackup_data 32 erasure os-vol-bu
ceph osd pool set ecbackup_data allow_ec_overwrites true
rbd pool init ecbackup
rbd pool init ecbackup_data

# create auth keyring

ceph auth get-or-create client.ecbackup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=ecbackup, allow rwx pool=ecbackup_data, allow rx pool=volumes, allow rx pool=ecvolumes, allow rx pool=ecvolumes_data' -o /etc/ceph/ceph.client.ecbackup.keyring

# send keyrings and conf files to controller for further distribution

scp /etc/ceph/ceph.client.ecbackup.keyring $OS_CONTROLLER_NM:~
ceph auth get-key client.ecbackup|ssh $OS_CONTROLLER_NM tee ~/client.ecbackup.key

exit
