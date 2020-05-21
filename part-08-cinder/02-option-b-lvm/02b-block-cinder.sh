#!/bin/bash

# OPTION B: LVM BACKED CINDER

# make sure packages are installed

dnf -y install lvm2 device-mapper-persistent-data

# create LVM PVs

pvcreate /dev/vd{b,c,d,e}

# create VG to simulate SSD storage

vgcreate cindervols-ssd /dev/vd{b,c}

# create VG to simulate HDD storage

vgcreate cindervols-hdd /dev/vd{d,e}

# apply device filters to LVM

l=$(sed -n '/# filter = /=' /etc/lvm/lvm.conf|tail -n1);sed -i "${l}a filter = [ 'a|vda|','a|vdb|','a|vdc|','a|vdd|','a|vde|','r|.*|' ]" /etc/lvm/lvm.conf

# install packages

dnf -y --enablerepo=PowerTools install openstack-cinder targetcli python3-keystone

# conf file work

./bak.sh /etc/cinder/cinder.conf

./conf.sh /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:${OS_CINDERDBPW}@${OS_CONTROLLER_NM}/cinder
./conf.sh /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:${OS_RMQPW}@${OS_CONTROLLER_NM}
./conf.sh /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
./conf.sh /etc/cinder/cinder.conf DEFAULT my_ip $OS_BLOCK_IP
./conf.sh /etc/cinder/cinder.conf DEFAULT enabled_backends lvm-ssd,lvm-hdd
./conf.sh /etc/cinder/cinder.conf DEFAULT glance_api_servers http://${OS_CONTROLLER_NM}:9292
./conf.sh /etc/cinder/cinder.conf DEFAULT default_volume_type HDD
./conf.sh /etc/cinder/cinder.conf keystone_authtoken www_authenticate_uri http://controller:5000
./conf.sh /etc/cinder/cinder.conf keystone_authtoken auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/cinder/cinder.conf keystone_authtoken memcached_servers ${OS_CONTROLLER_NM}:11211
./conf.sh /etc/cinder/cinder.conf keystone_authtoken auth_type password
./conf.sh /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
./conf.sh /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
./conf.sh /etc/cinder/cinder.conf keystone_authtoken project_name service
./conf.sh /etc/cinder/cinder.conf keystone_authtoken username cinder
./conf.sh /etc/cinder/cinder.conf keystone_authtoken password $OS_CINDERPW
./conf.sh /etc/cinder/cinder.conf backend_defaults volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
./conf.sh /etc/cinder/cinder.conf backend_defaults target_protocol iscsi
./conf.sh /etc/cinder/cinder.conf backend_defaults target_helper lioadm
./conf.sh /etc/cinder/cinder.conf lvm-ssd volume_group cindervols-ssd
./conf.sh /etc/cinder/cinder.conf lvm-ssd volume_backend_name LVM-SSD
./conf.sh /etc/cinder/cinder.conf lvm-hdd volume_group cindervols-hdd
./conf.sh /etc/cinder/cinder.conf lvm-hdd volume_backend_name LVM-HDD
./conf.sh /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

# enable and start services
for i in enable start;do systemctl $i openstack-cinder-volume target;done

exit
