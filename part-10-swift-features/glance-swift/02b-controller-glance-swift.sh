#!/bin/bash
# - OPTION B: MULTI TENANT
# images stored in tenant account
# prob doesn't make sense for ceph backend

# conf file work

./conf.sh /etc/glance/glance-api.conf glance_store swift_store_multi_tenant True

# restart api

systemctl restart openstack-glance-api

exit
