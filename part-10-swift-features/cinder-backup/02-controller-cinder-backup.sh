#!/bin/bash

# enable backup feature in horizon

sed -i '/OPENSTACK_CINDER_FEATURES/,/\}/ s/False/True/' /usr/share/openstack-dashboard/openstack_dashboard/defaults.py

systemctl restart httpd

exit
