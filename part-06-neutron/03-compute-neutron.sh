#!/bin/bash

source ~/os-env

# install packages

dnf -y --enablerepo=PowerTools install openstack-neutron-openvswitch iptables-ebtables ipset

# init openvswitch

for i in enable start;do systemctl $i openvswitch;done

./bak.sh /etc/neutron/neutron.conf

./conf.sh /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:${OS_RMQPW}@${OS_CONTROLLER_NM}
./conf.sh /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
./conf.sh /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/neutron/neutron.conf keystone_authtoken auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/neutron/neutron.conf keystone_authtoken memcached_servers ${OS_CONTROLLER_NM}:11211
./conf.sh /etc/neutron/neutron.conf keystone_authtoken auth_type password
./conf.sh /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
./conf.sh /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
./conf.sh /etc/neutron/neutron.conf keystone_authtoken project_name service
./conf.sh /etc/neutron/neutron.conf keystone_authtoken username neutron
./conf.sh /etc/neutron/neutron.conf keystone_authtoken password $OS_NEUTRONPW
./conf.sh /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

./bak.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini

./conf.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $OS_COMPUTE_TNT_IP
./conf.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
./conf.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
./conf.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid

./conf.sh /etc/nova/nova.conf neutron url http://${OS_CONTROLLER_NM}:9696
./conf.sh /etc/nova/nova.conf neutron auth_url http://${OS_CONTROLLER_NM}:5000
./conf.sh /etc/nova/nova.conf neutron auth_type password
./conf.sh /etc/nova/nova.conf neutron project_domain_name default
./conf.sh /etc/nova/nova.conf neutron user_domain_name default
./conf.sh /etc/nova/nova.conf neutron region_name $OS_REGION
./conf.sh /etc/nova/nova.conf neutron project_name service
./conf.sh /etc/nova/nova.conf neutron username neutron
./conf.sh /etc/nova/nova.conf neutron password $OS_NEUTRONPW

# this dir isn't created properly, create it now
install -d /var/lib/neutron/tmp -o neutron -g neutron

systemctl restart openstack-nova-compute

for i in enable start;do systemctl $i neutron-openvswitch-agent;done

exit
