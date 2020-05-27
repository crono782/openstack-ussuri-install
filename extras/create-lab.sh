#!/bin/sh

for i in ceph controller compute network;do qemu-img create -f qcow2 -F qcow2 -b /data/images/centos8.qcow2 /data/images/os-$i.qcow2;done
for i in $(seq 1 4);do qemu-img create -f qcow2 /data/disks/os-ceph-data$i.qcow2 20G;done

virt-install -n os-controller --os-type Linux --os-variant centos7.0 --ram 8192 --vcpus 2 --import --disk /data/images/os-controller.qcow2 --network bridge:br0 --graphics vnc --noautoconsole

virt-install -n os-compute --os-type Linux --os-variant centos7.0 --ram 16384 --vcpus 2 --cpu host-passthrough --import --disk /data/images/os-compute.qcow2 --network bridge:br0 --network bridge:br2 --graphics vnc --noautoconsole

virt-install -n os-network --os-type Linux --os-variant centos7.0 --ram 2048 --vcpus 1 --import --disk /data/images/os-network.qcow2 --network bridge:br0 --network bridge:br2 --network bridge:br4 --graphics vnc --noautoconsole

virt-install --name os-ceph --os-type Linux --os-variant centos7.0 --ram 4096 --vcpus 1 --import --disk /data/images/os-ceph.qcow2 --disk /data/disks/os-ceph-data1.qcow2 --disk /data/disks/os-ceph-data2.qcow2 --disk /data/disks/os-ceph-data3.qcow2 --disk /data/disks/os-ceph-data4.qcow2 --network bridge:br0 --graphics vnc --noautoconsole

./bootstraphost.exp os-controller controller ens3 10.10.10.100/24
./bootstraphost.exp os-compute compute ens3 10.10.10.101/24
./bootstraphost.exp os-network network ens3 10.10.10.102/24
./bootstraphost.exp os-ceph ceph ens3 10.10.10.110/24

for i in controller compute network ceph;do ssh-copy-id $i;done

exit
