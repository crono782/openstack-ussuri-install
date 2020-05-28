#!/bin/sh

# configure cinder to use barbican keys for encrypted volumes

./conf.sh /etc/cinder/cinder.conf key_manager backend barbican

systemctl restart openstack-cinder-api

source ~/adminrc

openstack volume type create --encryption-provider luks --encryption-cipher aes-xts-plain64 --encryption-key-size 256 --encryption-control-location front-end --property volume_backend_name=CephRBD --description "LUKS encrypted Standard Ceph RBD volume." Standard-CephRBD-Encrypted

openstack volume type create --encryption-provider luks --encryption-cipher aes-xts-plain64 --encryption-key-size 256 --encryption-control-location front-end --property volume_backend_name=CephRBD-EC --description "LUKS encrypted Cold (erasure coded) Ceph RBD volume." Cold-CephRBD-EC-Encrypted
