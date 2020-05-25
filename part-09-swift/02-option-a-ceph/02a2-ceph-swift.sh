#!/bin/sh

source ~/os-env

sed -i "/^\[client.rgw.${OS_CEPH_NM}\]/a \
rgw_swift_account_in_url = True\n\
rgw_keystone_url = http://${OS_CONTROLLER_NM}:5000\n\
rgw_keystone_api_version = 3\n\
rgw_keystone_admin_user = swift\n\
rgw_keystone_admin_password = $OS_SWIFTPW\n\
rgw_keystone_admin_tenant = service\n\
rgw_keystone_admin_domain = default\n\
rgw_keystone_accepted_roles = admin, member\n\
rgw_keystone_token_cache_size = 10\n\
rgw_keystone_revocation_interval = 300\n\
rgw_keystone_make_new_tenants = true\n\
rgw_keystone_implicit_tenants = true\n\
rgw_rgw_swift_versioning_enabled = true\n\
rgw_s3_auth_use_keystone = true\n\
rgw_enable_apis = swift, s3\n\
rgw_keystone_verify_ssl = false\n\
" /etc/ceph/ceph.conf

systemctl restart ceph-radosgw@rgw.${OS_CEPH_NM}

exit
