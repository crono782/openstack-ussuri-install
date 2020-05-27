#!/bin/bash

source ~/os-env

# create cinder database

./dbcreate.sh cinder cinder $OS_CINDERDBPW

# create user, add role, create services and endpoints

source ~/adminrc

openstack user create --domain default --password $OS_CINDERPW cinder

openstack role add --project service --user cinder admin

openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2

openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

./endpoint.sh volumev2 8776/v2/%\(project_id\)s

./endpoint.sh volumev3 8776/v3/%\(project_id\)s

# install packages

dnf -y install openstack-cinder

# conf file work

./bak.sh /etc/cinder/cinder.conf

./conf.sh /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:${OS_CINDERDBPW}@${OS_CONTROLLER_NM}/cinder
./conf.sh /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:${OS_RMQPW}@${OS_CONTROLLER_NM}
./conf.sh /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
./conf.sh /etc/cinder/cinder.conf DEFAULT my_ip $OS_CONTROLLER_IP
./conf.sh /etc/cinder/cinder.conf DEFAULT default_volume_type HDD
./conf.sh /etc/cinder/cinder.conf DEFAULT enabled_backends lvm-ssd,lvm-hdd
./conf.sh /etc/cinder/cinder.conf keystone_authtoken www_authenticate_uri http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/cinder/cinder.conf keystone_authtoken auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/cinder/cinder.conf keystone_authtoken memcached_servers ${OS_CONTROLLER_NM}:11211
./conf.sh /etc/cinder/cinder.conf keystone_authtoken auth_type password
./conf.sh /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
./conf.sh /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
./conf.sh /etc/cinder/cinder.conf keystone_authtoken project_name service
./conf.sh /etc/cinder/cinder.conf keystone_authtoken username cinder
./conf.sh /etc/cinder/cinder.conf keystone_authtoken password $OS_CINDERPW
./conf.sh /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

# populate database

su -s /bin/sh -c "cinder-manage db sync" cinder

# configure nova to use cinder

./conf.sh /etc/nova/nova.conf cinder os_region_name $OS_REGION

# restart nova api service

systemctl restart openstack-nova-api

# enable and start services

for i in enable start;do systemctl $i openstack-cinder-{api,scheduler};done

exit
