#!/bin/bash

source ~/os-env

# create neutron database

./dbcreate.sh neutron neutron $OS_NEUTRONDBPW

# create user, add role, create service and endpoints

source ~/adminrc

openstack user create --domain default --password $OS_NEUTRONPW neutron

openstack role add --project service --user neutron admin

openstack service create --name neutron --description "OpenStack Networking" network

./endpoint.sh network 9696

# install packages

dnf -y install openstack-neutron openstack-neutron-ml2

# conf file work

./bak.sh /etc/neutron/neutron.conf

./conf.sh /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:${OS_NEUTRONDBPW}@${OS_CONTROLLER_NM}/neutron
./conf.sh /etc/neutron/neutron.conf DEFAULT core_plugin ml2
./conf.sh /etc/neutron/neutron.conf DEFAULT service_plugins router
./conf.sh /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true
./conf.sh /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:${OS_RMQPW}@${OS_CONTROLLER_NM}
./conf.sh /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
./conf.sh /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
./conf.sh /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true
./conf.sh /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/neutron/neutron.conf keystone_authtoken auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/neutron/neutron.conf keystone_authtoken memcached_servers ${OS_CONTROLLER_NM}:11211
./conf.sh /etc/neutron/neutron.conf keystone_authtoken auth_type password
./conf.sh /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
./conf.sh /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
./conf.sh /etc/neutron/neutron.conf keystone_authtoken project_name service
./conf.sh /etc/neutron/neutron.conf keystone_authtoken username neutron
./conf.sh /etc/neutron/neutron.conf keystone_authtoken password $OS_NEUTRONPW
./conf.sh /etc/neutron/neutron.conf nova auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/neutron/neutron.conf nova auth_type password
./conf.sh /etc/neutron/neutron.conf nova project_domain_name default
./conf.sh /etc/neutron/neutron.conf nova user_domain_name default
./conf.sh /etc/neutron/neutron.conf nova region_name $OS_REGION
./conf.sh /etc/neutron/neutron.conf nova project_name service
./conf.sh /etc/neutron/neutron.conf nova username nova
./conf.sh /etc/neutron/neutron.conf nova password $OS_NOVAPW
./conf.sh /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

./bak.sh /etc/neutron/plugins/ml2/ml2_conf.ini

./conf.sh /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
./conf.sh /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
./conf.sh /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
./conf.sh /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
./conf.sh /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
./conf.sh /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
./conf.sh /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true

./conf.sh /etc/nova/nova.conf neutron url http://${OS_CONTROLLER_NM}:9696
./conf.sh /etc/nova/nova.conf neutron auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/nova/nova.conf neutron auth_type password
./conf.sh /etc/nova/nova.conf neutron project_domain_name default
./conf.sh /etc/nova/nova.conf neutron user_domain_name default
./conf.sh /etc/nova/nova.conf neutron region_name $OS_REGION
./conf.sh /etc/nova/nova.conf neutron project_name service
./conf.sh /etc/nova/nova.conf neutron username neutron
./conf.sh /etc/nova/nova.conf neutron password $OS_NEUTRONPW
./conf.sh /etc/nova/nova.conf neutron service_metadata_proxy true
./conf.sh /etc/nova/nova.conf neutron metadata_proxy_shared_secret $OS_NEUTRON_METASECRET

# this dir isn't created properly, create it now
install -d /var/lib/neutron/tmp -o neutron -g neutron

# link plugin.ini
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

# populate database
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

# restart nova api
systemctl restart openstack-nova-api

# start service
for i in enable start;do systemctl $i neutron-server;done

exit
