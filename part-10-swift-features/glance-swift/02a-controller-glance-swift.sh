#!/bin/bash
# - OPTION A: SINGLE TENANT
# all images stored in service account
# doesn't make a lot of sense for ceph backend

source ~/os-env

# conf file work

./conf.sh /etc/glance/glance-api.conf glance_store default_swift_reference glance-swift
./conf.sh /etc/glance/glance-api.conf glance_store swift_store_config_file /etc/glance/glance-swift.conf

cat << EOF >> /etc/glance/glance-swift.conf
[glance-swift]
user = service:glance
key = $OS_GLANCEPW
user_domain_id = default
project_domain_id = default
auth_version = 3
auth_address = http://${OS_CONTROLLER_NM}:5000/v3
EOF

# restart api

systemctl restart openstack-glance-api

exit
