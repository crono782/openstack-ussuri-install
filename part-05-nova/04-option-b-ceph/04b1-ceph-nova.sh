#!/bin/sh

# OPTION B: Ceph backed Nova VM images
# "Option A" is just leave it like it is. running vms are stored
# locally on the hypervisor. bad for resiliency/HA. If using ceph,
# configure like this 

source ~/os-env

ceph osd pool create vms 32
rbd pool init vms

ceph auth get-or-create client.vms mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=vms, allow rx pool=images' -o /etc/ceph/ceph.client.vms.keyring

uuidgen|tee /etc/ceph/nova.vms.uuid.txt
scp /etc/ceph/nova.vms.uuid.txt $OS_COMPUTE_NM:~
scp /etc/ceph/ceph.client.vms.keyring $OS_COMPUTE_NM:~
scp /etc/ceph/ceph.conf $OS_COMPUTE_NM:~
ceph auth get-key client.vms|ssh $OS_COMPUTE_NM tee ~/client.vms.key

exit
