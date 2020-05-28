#!/bin/sh

# configure nova to use barbican keys for encrypted volumes

./conf.sh /etc/nova/nova.conf key_manager backend barbican

systemctl restart openstack-nova-compute
