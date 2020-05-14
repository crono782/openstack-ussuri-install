#!/bin/bash

# install packages

dnf -y --enablerepo=PowerTools install openstack-neutron openstack-neutron-openvswitch libibverbs iptables-ebtables NetworkManager-ovs

systemctl restart NetworkManager

# init openvswitch

for i in enable start;do systemctl $i openvswitch;done

# create provider bridge

nmcli con del ens5
nmcli con add type ovs-bridge con-name br-provider ifname br-provider
nmcli con add type ovs-port con-name ovs-port-br-provider ifname br-provider master br-provider
nmcli con add type ovs-interface con-name ovs-if-br-provider ifname br-provider master br-provider slave-type ovs-port ipv4.method disabled ipv6.method ignore
nmcli con add type ovs-port con-name ovs-port-ens5 ifname ens5 master br-provider
nmcli con add type ethernet con-name ovs-if-ens5 ifname ens5 master ovs-port-ens5

# quick verification

ovs-vsctl show

# conf file work

./bak.sh /etc/neutron/neutron.conf

./conf.sh /etc/neutron/neutron.conf DEFAULT core_plugin ml2
./conf.sh /etc/neutron/neutron.conf DEFAULT service_plugins router
./conf.sh /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true
./conf.sh /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:password@controller
./conf.sh /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
./conf.sh /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
./conf.sh /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true
./conf.sh /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://controller:5000
./conf.sh /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:5000
./conf.sh /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
./conf.sh /etc/neutron/neutron.conf keystone_authtoken auth_type password
./conf.sh /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
./conf.sh /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
./conf.sh /etc/neutron/neutron.conf keystone_authtoken project_name service
./conf.sh /etc/neutron/neutron.conf keystone_authtoken username neutron
./conf.sh /etc/neutron/neutron.conf keystone_authtoken password password
./conf.sh /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

./bak.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini

./conf.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings provider:br-provider
./conf.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip 10.10.20.102
./conf.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
./conf.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
./conf.sh /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid

./bak.sh /etc/neutron/l3_agent.ini

./conf.sh /etc/neutron/l3_agent.ini DEFAULT interface_driver openvswitch
# empty quotes so we get a intentionally blank value
./conf.sh /etc/neutron/l3_agent.ini DEFAULT external_network_bridge ''

./bak.sh /etc/neutron/dhcp_agent.ini

./conf.sh /etc/neutron/dhcp_agent.ini DEFAULT interface_driver openvswitch
./conf.sh /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
./conf.sh /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

./bak.sh /etc/neutron/metadata_agent.ini

./conf.sh /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host controller
./conf.sh /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret metasecret

# this dir isn't created properly, create it now
install -d /var/lib/neutron/tmp -o neutron -g neutron

# start services

for i in enable start;do systemctl $i neutron-{openvswitch,dhcp,metadata,l3}-agent;done

exit
