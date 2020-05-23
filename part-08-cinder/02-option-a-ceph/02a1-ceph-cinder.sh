#!/bin/bash

# OPTION A: CEPH RBD BACKED CINDER

source ~/os-env

# create erasure code profile

ceph osd erasure-code-profile set ostack k=2 m=1 plugin=jerasure crush-failure-domain=osd technique=reed_sol_van

# create pool for standard volumes

ceph osd pool create volumes 32
rbd pool init volumes

# create pools for erasure coded volumes

ceph osd pool create ecvolumes 8
ceph osd pool create ecvolumes_data 32 erasure ostack
ceph osd pool set ecvolumes_data allow_ec_overwrites true
rbd pool init ecvolumes
rbd pool init ecvolumes_data

# create auth keyrings

ceph auth get-or-create client.volumes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images' -o /etc/ceph/ceph.client.volumes.keyring

ceph auth get-or-create client.ecvolumes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=ecvolumes, allow rwx pool=ecvolumes_data, allow rx pool=images' -o /etc/ceph/ceph.client.ecvolumes.keyring

# send keyrings and conf files to controller for further distribution

scp /etc/ceph/ceph.client.volumes.keyring $OS_CONTROLLER_NM:~
scp /etc/ceph/ceph.client.ecvolumes.keyring $OS_CONTROLLER_NM:~
scp /etc/ceph/ceph.conf $OS_CONTROLLER_NM:~
ceph auth get-key client.volumes|ssh $OS_CONTROLLER_NM tee ~/client.volumes.key
ceph auth get-key client.ecvolumes|ssh $OS_CONTROLLER_NM tee ~/client.ecvolumes.key

exit
