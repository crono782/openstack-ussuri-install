# examples showing creating different vms with multiple block devices, nics, or special cpu profiles

# example showing regular vm w/ no special setup
virt-install -n os-controller --os-type Linux --os-variant centos7.0 --import --disk os-controller.qcow2 --ram 8192 --vcpus 2 --network bridge:br0 --nographics --noautoconsole

# example showing vm w/ nested kvm cpu profile and multiple networks (i.e. compute node)
virt-install -n os-compute --os-type Linux --os-variant centos7.0 --import --disk os-compute.qcow2 --ram 8192 --vcpus 2 --cpu host-passthrough --network bridge:br0 --network bridge:br2 --nographics --noautoconsole

# example showing vm w/ multiple networks (i.e. network node)
virt-install -n network --os-type Linux --os-variant centos7.0 --import --disk  network.qcow2 --ram 1024 --vcpus 1 --network bridge:br0 --network bridge:br4 --network bridge:br4 --nographics --noautoconsole

# example showing vm w/ multiple disks (i.e. ceph/block/object node)
virt-install --name os-ceph --os-type Linux --os-variant centos7.0 --import --disk os-ceph.qcow2 --disk os-ceph-data1.qcow2 --disk os-ceph-data2.qcow2 --disk os-ceph-data3.qcow2 --ram 2048 --vcpus 1 --network bridge:br0 --nographics --noautoconsole
