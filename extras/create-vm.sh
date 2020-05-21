# examples showing creating different vms with multiple block devices, nics, or special cpu profiles

# example controller vm. no special setup
virt-install -n os-controller --os-type Linux --os-variant centos7.0 --ram 8192 --vcpus 2 --import --disk /data/images/os-controller.qcow2 --network bridge:br0 --graphics vnc --noautoconsole

# example compute vm. host cpu passthrough for nested kvm and tenant network
virt-install -n os-compute --os-type Linux --os-variant centos7.0 --ram 16384 --vcpus 2 --cpu host-passthrough --import --disk /data/images/os-compute.qcow2 --network bridge:br0 --network bridge:br2 --graphics vnc --noautoconsole

# example network vm. tenant and provider networks
virt-install -n network --os-type Linux --os-variant centos7.0 --ram 2048 --vcpus 1 --import --disk /data/images/os-network.qcow2 --network bridge:br0 --network bridge:br4 --network bridge:br4 --graphics vnc --noautoconsole

# example ceph, block, or object vms. multiple disks
virt-install --name os-ceph --os-type Linux --os-variant centos7.0 --ram 4096 --vcpus 1 --import --disk /data/images/os-ceph.qcow2 --disk /data/disks/os-ceph-data1.qcow2 --disk /data/disks/os-ceph-data2.qcow2 --disk /data/disks/os-ceph-data3.qcow2 --disk /data/disks/os-ceph-data4.qcow2 --network bridge:br0 --graphics vnc --noautoconsole
