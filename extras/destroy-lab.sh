#!/bin/sh
for i in ceph controller compute network;do virsh destroy os-$i;done
for i in ceph controller compute network;do virsh undefine os-$i --remove-all-storage;done
