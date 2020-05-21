#!/bin/bash

# OPTION A: CEPH RBD BACKED GLANCE

source ~/os-env

ceph osd pool create images 32
rbd pool init images
ceph auth get-or-create client.images mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images' -o /etc/ceph/ceph.client.images.keyring

scp /etc/ceph/ceph.client.images.keyring $OS_CONTROLLER_NM:~
scp /etc/ceph/ceph.conf $OS_CONTROLLER_NM:~

exit
