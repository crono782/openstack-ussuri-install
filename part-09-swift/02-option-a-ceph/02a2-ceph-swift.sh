#!/bin/sh

source ~/os-env

sed -i "/^\[client.rgw.${OS_CEPH_NM}\]/a \
\
# Keystone information \
rgw swift account in url = True \
rgw_keystone_url = http://${OS_CONTROLLER_NM}:5000 \
rgw_keystone_admin_user = swift \
rgw_keystone_admin_password = $OS_SWIFTPW \
rgw_keystone_admin_tenant = service \
rgw_keystone_accepted_roles = admin \
rgw_keystone_token_cache_size = 10 \
rgw_keystone_revocation_interval = 300 \
rgw_keystone_make_new_tenants = true \
rgw_s3_auth_use_keystone = true \
rgw_keystone_verify_ssl = false \
" /etc/ceph/ceph.conf

systemctl restart ceph-radosgw@rgw.${OS_CEPH_NM}
