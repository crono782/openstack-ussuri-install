# examples showing creating thin block devices or images w/ backing stores

# example creating 20G block device, but thin provisioned
qemu-img create -f qcow2 object1.qcow2 20G

# example "cloning block device using a backing store" (thin clone)
qemu-img create -f qcow2 -F qcow2 -b centos7tpl.qcow2 controller.qcow2

# example to create block devices for this tutorial
for i in ceph controller compute network;do qemu-img create -f qcow2 -F qcow2 -b /data/images/centos8.qcow2 /data/images/os-$i.qcow2;done

for i in $(seq 1 4);do qemu-img create -f qcow2 /data/disks/os-ceph-data$i.qcow2 20G;done
